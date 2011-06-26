package Carton;

use strict;
use 5.008_001;
use version; our $VERSION = qv('v0.1.0');

use Cwd;
use Config;
use Getopt::Long;
use Term::ANSIColor qw(colored);

use Carton::Tree;

our $Colors = {
    SUCCESS => 'green',
    INFO    => 'cyan',
    ERROR   => 'red',
};

sub new {
    my $class = shift;
    bless {
        path  => 'local',
        color => 1,
        verbose => 0,
        cpanm => $ENV{PERL_CARTON_CPANM} || 'cpanm',
    }, $class;
}

sub work_file {
    my($self, $file) = @_;
    return "$self->{work_dir}/$file";
}

sub run {
    my($self, @args) = @_;

    $self->{work_dir} = $ENV{PERL_CARTON_HOME} || (Cwd::cwd() . "/.carton");
    mkdir $self->{work_dir}, 0777 unless -e $self->{work_dir};

    local @ARGV = @args;
    my @commands;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_ignore_case", "pass_through" ],
    );
    $p->getoptions(
        "h|help"    => sub { unshift @commands, 'help' },
        "v|version" => sub { unshift @commands, 'version' },
        "color!"    => \$self->{color},
        "verbose!"  => \$self->{verbose},
    );

    push @commands, @ARGV;

    my $cmd = shift @commands || 'help';
    my $call = $self->can("cmd_$cmd");

    if ($call) {
        $self->$call(@commands);
    } else {
        die "Could not find command '$cmd'\n";
    }
}

sub parse_options {
    my($self, $args, @spec) = @_;
    Getopt::Long::GetOptionsFromArray($args, @spec);
}

sub print {
    my($self, $msg, $type) = @_;
    $msg = colored $msg, $Colors->{$type} if $type && $self->{color};
    print $msg;
}

sub check {
    my($self, $msg) = @_;
    $self->print("✓ ", "SUCCESS");
    $self->print($msg . "\n");
}

sub error {
    my($self, $msg) = @_;
    $self->print($msg, "ERROR");
    exit(1);
}

sub cmd_help {
    my $self = shift;
    my $cmd  = $_[0] ? "carton-$_[0]" : "carton";
    system "perldoc", $cmd;
}

sub cmd_version {
    print "carton $VERSION\n";
}

sub cmd_install {
    my($self, @args) = @_;

    $self->parse_options(\@args, "p|path=s", \$self->{path}, "deployment!" => \$self->{deployment});

    if (@args) {
        $self->print("Installing modules from the command line\n");
        $self->install_modules(@args);
        $self->update_packages;
    } elsif (my $file = $self->has_build_file) {
        $self->print("Installing modules using $file\n");
        $self->install_from_build_file($file);
        $self->update_packages;
    } elsif (-e 'carton.lock') {
        $self->print("Installing modules using carton.lock\n");
        $self->install_from_spec();
    } else {
        $self->error("Can't locate build file or carton.lock\n");
    }

    $self->print("Complete! Modules were installed into $self->{path}\n", "SUCCESS");
}

sub has_build_file {
    my $self = shift;

    # deployment mode ignores build files and only uses carton.lock
    return if $self->{deployment};

    my $file = (grep -e, qw( Build.PL Makefile.PL ))[0]
        or return;

    if ($self->mtime($file) > $self->mtime("carton.lock")) {
        return $file;
    }

    return;
}

sub mtime {
    my($self, $file) = @_;
    return (stat($file))[9] || 0;
}

sub install_from_build_file {
    my($self, $file) = @_;
    $self->run_cpanm("--installdeps", ".")
        or $self->error("Installing modules failed\n");
}

sub install_modules {
    my($self, @args) = @_;
    $self->run_cpanm(@args)
        or $self->error("Installing modules failed\n");
}

sub install_from_spec {
    my $self = shift;

    my $data = $self->parse_json('carton.lock')
        or $self->error("Couldn't parse carton.lock: Remove the file and run `carton install` to rebuild it.\n");

    my $index = $self->build_index($data->{modules});
    my $file = $self->build_mirror_file($index);

    my $tree = $self->build_tree($data->{modules});
    my @root = map $_->key, $tree->children;

    $self->run_cpanm(
        "--mirror", "http://backpan.perl.org/",
        "--mirror", "http://cpan.cpantesters.org/",
        "--index", $file, @root,
    );
}

sub build_mirror_file {
    my($self, $index) = @_;

    my @packages = $self->build_packages($index);

    my $file = $self->work_file("02packages.details.txt");
    open my $fh, ">", $file or die $!;

    print $fh <<EOF;
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in carton.lock
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Carton $Carton::VERSION
Line-Count:   @{[ scalar(@packages) ]}
Last-Updated: @{[ scalar localtime ]}

EOF
    for my $p (@packages) {
        print $fh sprintf "%s %s  %s\n", pad($p->[0], 32), pad($p->[1] || 'undef', 10, 1), $p->[2];
    }

    return $file;
}

sub pad {
    my($str, $len, $left) = @_;

    my $howmany = $len - length($str);
    return $str if $howmany <= 0;

    my $pad = " " x $howmany;
    return $left ? "$pad$str" : "$str$pad";
}

sub build_packages {
    my($self, $index) = @_;

    my @packages;
    for my $package (sort keys %$index) {
        my $module = $index->{$package};
        push @packages, [ $package, $module->{version}, $module->{meta}{pathname} ];
    }

    return @packages;
}

*cmd_list = \&cmd_show;

sub cmd_show {
    my($self, @args) = @_;

    require Module::CoreList;

    my $tree_mode;
    $self->parse_options(\@args, "tree!" => \$tree_mode);

    my $data = $self->parse_json('carton.lock')
        or $self->error("Can't find carton.lock: Run `carton install` to rebuild the spec file.\n");

    if ($tree_mode) {
        my %seen;
        my $tree = $self->build_tree($data->{modules});
        $tree->walk_down(sub {
            my($node, $depth, $parent) = @_;

            return $tree->abort if $seen{$node->key}++;

            if ($node->metadata->{dist}) {
                print "  " x $depth;
                print $node->metadata->{dist}, "\n";
            } elsif (!$Module::CoreList::version{$]+0}{$node->key}) {
                warn "Couldn't find ", $node->key, "\n";
            }
        });
    } else {
        for my $module (values %{$data->{modules} || {}}) {
            printf "$module->{dist}\n";
        }
    }
}

sub build_index {
    my($self, $modules) = @_;

    my $index;

    for my $name (keys %$modules) {
        my $metadata = $modules->{$name};
        my $provides = $metadata->{provides};
        for my $mod (keys %$provides) {
            $index->{$mod} = { version => $provides->{$mod}, meta => $metadata };
        }
    }

    return $index;
}

sub build_tree {
    my($self, $modules) = @_;

    my $idx  = $self->build_index($modules);
    my $pool = { %$modules }; # copy

    my $tree = Carton::Tree->new;

    while (my $pick = (keys %$pool)[0]) {
        $self->_build_tree($pick, $tree, $tree, $pool, $idx);
    }

    $tree->finalize;

    return $tree;
}

sub _build_tree {
    my($self, $elem, $tree, $curr_node, $pool, $idx) = @_;

    if (my $cached = Carton::TreeNode->cached($elem)) {
        $curr_node->add_child($cached);
        return;
    }

    my $node = Carton::TreeNode->new($elem, $pool);
    $curr_node->add_child($node);

    for my $child ( $self->build_deps($node->metadata, $idx) ) {
        $self->_build_tree($child, $tree, $node, $pool, $idx);
    }
}

sub build_deps {
    my($self, $meta, $idx) = @_;

    my @deps;
    for my $requires (values %{$meta->{requires}}) {
        for my $module (keys %$requires) {
            next if $module eq 'perl';
            if (exists $idx->{$module}) {
                push @deps, $idx->{$module}{meta}{name};
            } else {
                push @deps, $module;
            }
        }
    }

    return @deps;
}

sub cmd_check {
    my $self = shift;

    $self->check_cpanm_version;
    # check carton.lock and extlib?
}

sub check_cpanm_version {
    my $self = shift;

    my $version = (`$self->{cpanm} --version` =~ /version (\S+)/)[0];
    unless ($version && $version >= 1.5) {
        $self->error("carton needs cpanm version >= 1.5. You have " . ($version || "(not installed)") . "\n");
    }
    $self->check("You have cpanm $version");
}

sub cmd_update {
    # "cleanly" update distributions in extlib
    # rebuild the tree, update modules with DFS
}

sub cmd_exec {
    # setup lib::core::only, -L env, put extlib/bin into PATH and exec script
}

sub run_cpanm {
    my($self, @args) = @_;
    local $ENV{PERL_CPANM_OPT};
    !system $self->{cpanm}, "--quiet", "--notest", "-L", $self->{path}, @args;
}

sub parse_json {
    my($self, $file) = @_;

    open my $fh, "<", $file or return;

    require JSON;
    JSON::decode_json(join '', <$fh>);
}

sub update_packages {
    my $self = shift;

    my %locals = $self->find_locals;

    my $spec = {
        modules => \%locals,
    };

    require JSON;
    open my $fh, ">", "carton.lock" or die $!;
    print $fh JSON->new->pretty->encode($spec);

    return 1;
}

sub find_locals {
    my $self = shift;

    require File::Find;

    my @locals;
    my $wanted = sub {
        if ($_ eq 'local.json') {
            push @locals, $File::Find::name;
        }
    };
    File::Find::find($wanted, "$self->{path}/lib/perl5/auto/meta");

    return map { my $module = $self->parse_json($_); ($module->{name} => $module) } @locals;
}

1;
__END__
