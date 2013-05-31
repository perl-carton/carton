package Carton::CLI;
use strict;
use warnings;

use Cwd;
use Config;
use Getopt::Long;
use Term::ANSIColor qw(colored);

use Carton;
use Carton::Util;
use Carton::Error;
use Carton::Tree;
use Try::Tiny;

use constant { SUCCESS => 0, INFO => 1, WARN => 2, ERROR => 3 };

our $Colors = {
    SUCCESS, => 'green',
    WARN,    => 'yellow',
    INFO,    => 'cyan',
    ERROR,   => 'red',
};

sub new {
    my $class = shift;
    bless {
        color => 1,
        verbose => 0,
    }, $class;
}

sub carton {
    my $self = shift;
    $self->{carton} ||= Carton->new;
}

sub work_file {
    my($self, $file) = @_;
    return "$self->{work_dir}/$file";
}

sub run {
    my($self, @args) = @_;
    $self->{work_dir} = $ENV{PERL_CARTON_HOME} || (Cwd::cwd() . "/.carton");
    mkdir $self->{work_dir}, 0777 unless -e $self->{work_dir};

    $self->parse_carton_options(\@args)
        or $self->error("Invalid option, see 'carton help'.\n");

    my @commands = @args;

    my $cmd = shift @commands || 'install';
    my $call = $self->can("cmd_$cmd");

    if ($call) {
        try {
            $self->$call(@commands);
        } catch {
            /Carton::Error::CommandExit/ and return;
            die $_;
        }
    } else {
        $self->error("Could not find command '$cmd'\n");
    }
}

sub commands {
    my $self = shift;

    no strict 'refs';
    map { s/^cmd_//; $_ }
        grep /^cmd_(.*)/, sort keys %{__PACKAGE__."::"};
}

sub cmd_usage {
    my $self = shift;
    $self->print(<<HELP);
Usage: carton <command>

where <command> is one of:
  @{[ join ", ", $self->commands ]}

Run carton -h <command> for help.
HELP
}

sub parse_carton_options {
    my($self, $args) = @_;

    my @options;

    # carton itself's options has no arguments.
    while (scalar(@$args) > 0) {
        last unless $args->[0] =~ m!^-!;
        push @options, (shift @$args);
    }

    local @ARGV = @options;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_ignore_case" ],
    );
    $p->getoptions(
        "h|help"    => sub { unshift @$args, 'help' },
        "v|version" => sub { unshift @$args, 'version' },
        "color!"    => \$self->{color},
        "verbose!"  => \$self->{verbose},
    );
}

sub parse_options {
    my($self, $args, @spec) = @_;

    my $spec_index = 0;
    my @spec_keys = grep { ! ($spec_index++ % 2) } @spec; # even number members are spec_key (0 origin)
    my %opt_specs;
    for my $def (@spec_keys) {
        next if $def !~ /^([-a-zA-Z0-9]+)\|?([-a-zA-Z0-9]+)?(=?).*$/;
        my $v = $3 ? 1 : 0; # option with values, or not
        $opt_specs{$1} = $v;
        $opt_specs{$2} = $v if $2;
    }

    # split string with single option name and value like '-Ilib' into '-I' and 'lib'
    # bundling (ex: -abc) is disabled (by default)
    my @fixedargs = map { /^-([^-])(.+)$/ && $opt_specs{$1} ? ("-".$1, $2) : $_ } @$args;

    my $fence = 0;
    while ( $fence < scalar(@fixedargs) ) {
        last unless $fixedargs[$fence] =~ m!^--?([-a-zA-Z0-9]+)$!;
        $fence++;
        $fence++ if defined($opt_specs{$1}) && $opt_specs{$1}; # option with values
    }
    my @options = splice(@fixedargs, 0, $fence);

    unshift @$args, @fixedargs;
    splice @$args, scalar(@fixedargs);

    local @ARGV = @options;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_ignore_case" ],
    );
    $p->getoptions(@spec)
        or return undef; # unknown options or invalid parse result
    shift @$args if $args->[0] and $args->[0] eq '--';
    1; # success to parse
}

sub printf {
    my $self = shift;
    my $type = pop;
    my($temp, @args) = @_;
    $self->print(sprintf($temp, @args), $type);
}

sub print {
    my($self, $msg, $type) = @_;
    $msg = colored $msg, $Colors->{$type} if defined $type && $self->{color};
    my $fh = $type && $type >= WARN ? *STDERR : *STDOUT;
    print {$fh} $msg;
}

sub error {
    my($self, $msg) = @_;
    $self->print($msg, ERROR);
    Carton::Error::CommandExit->throw;
}

sub cmd_help {
    my $self = shift;
    my $module = $_[0] ? ("Carton::Doc::" . ucfirst $_[0]) : "Carton";
    system "perldoc", $module;
}

sub cmd_version {
    my $self = shift;
    $self->print("carton $Carton::VERSION\n");
}

sub cmd_bundle {
    my($self, @args) = @_;

    $self->parse_options(\@args, "p|path=s" => sub { $self->carton->{path} = $_[1] })
        or $self->error("Invalid option for 'bundle', see 'carton help bundle'.\n");

    my $lock = $self->find_lock;
    my $local_mirror = $self->carton->local_mirror;

    $self->carton->configure(
        lock => $lock,
        mirror_file => $self->mirror_file,
    );

    my $cpanfile = $self->has_cpanfile;

    if ($cpanfile && $lock) {
        $self->print("Bundling modules using $cpanfile\n");
        $self->carton->download_from_cpanfile($cpanfile, $local_mirror);
    } else {
        $self->error("Can't locate cpanfile and lock file. Run carton install first\n");
    }

    $self->printf("Complete! Modules were bundled into %s\n", $local_mirror, SUCCESS);
}

sub cmd_install {
    my($self, @args) = @_;

    $self->parse_options(
        \@args,
        "p|path=s"    => sub { $self->carton->{path} = $_[1] },
        "deployment!" => \$self->{deployment},
        "cached!"     => \$self->{use_local_mirror},
    )
        or $self->error("Invalid option for 'install', see 'carton help install'.\n") and return;

    my $lock = $self->find_lock;
    my $local_mirror = $self->carton->local_mirror;

    $self->carton->configure(
        lock => $lock,
        mirror_file => $self->mirror_file, # $lock object?
        ( $self->{use_local_mirror} && -d $local_mirror ? (mirror => $local_mirror) : () ),
    );

    my $cpanfile = $self->has_cpanfile;

    if (!$cpanfile) {
        $self->error("Can't locate cpanfile.\n");
    } elsif ($self->{deployment}) {
        $self->print("Installing modules using $cpanfile (deployment mode)\n");
        $self->carton->install_from_cpanfile($cpanfile);
    } else {
        $self->print("Installing modules using $cpanfile\n");
        $self->carton->install_from_cpanfile($cpanfile, 1);
        $self->carton->update_lock_file($self->lock_file);
    }

    $self->printf("Complete! Modules were installed into %s\n", $self->carton->{path}, SUCCESS);
}

sub mirror_file {
    my $self = shift;
    return $self->work_file("02packages.details.txt");
}

sub has_cpanfile {
    my $self = shift;

    return 'cpanfile' if -e 'cpanfile';
    return;
}

sub cmd_show {
    my($self, @args) = @_;

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install`\n");
    my $index = $self->carton->build_index($lock->{modules});

    for my $module (@args) {
        my $meta = $index->{$module}{meta}
            or $self->error("Couldn't locate $module in carton.lock\n");
        $self->print( Carton::Util::to_json($meta) );
    }
}

sub cmd_tree {
    my $self = shift;
    $self->cmd_list("--tree", @_);
}

sub cmd_list {
    my($self, @args) = @_;

    my $tree_mode;
    $self->parse_options(\@args, "tree!" => \$tree_mode)
        or $self->error("Invalid option for 'list', see 'carton help list'.\n") and return;

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install` to rebuild the lock file.\n");

    if ($tree_mode) {
        my $tree = $self->carton->build_tree($lock->{modules});
        $self->carton->walk_down_tree($tree, sub {
            my($module, $depth) = @_;
            my $line = " " x $depth . "$module->{dist}\n";
            $self->print($line);
        });
    } else {
        for my $module (values %{$lock->{modules} || {}}) {
            $self->print("$module->{dist}\n");
        }
    }
}

sub cmd_check {
    my($self, @args) = @_;

    my $file = $self->has_cpanfile
        or $self->error("Can't find a build file: nothing to check.\n");

    $self->parse_options(\@args, "p|path=s", sub { $self->carton->{path} = $_[1] })
        or $self->error("Invalid option for 'check', see 'carton help check'.\n");

    my $lock = $self->carton->build_lock;
    my @deps = $self->carton->list_dependencies;

    my $res = $self->carton->check_satisfies($lock, \@deps);

    my $ok = 1;
    if (@{$res->{unsatisfied}}) {
        $self->print("Following dependencies are not satisfied. Run `carton install` to install them.\n", WARN);
        for my $dep (@{$res->{unsatisfied}}) {
            $self->print("$dep->{module} " . ($dep->{version} ? "($dep->{version})" : "") . "\n");
        }
        $ok = 0;
    }

    if ($res->{superflous}) {
        $self->printf("Following modules are found in %s but couldn't be tracked from your $file\n",
                      $self->carton->{path}, WARN);
        $self->carton->walk_down_tree($res->{superflous}, sub {
            my($module, $depth) = @_;
            my $line = "  " x $depth . "$module->{dist}\n";
            $self->print($line);
        }, 1);
        $ok = 0;
    }

    if ($ok) {
        $self->printf("Dependencies specified in your $file are satisfied and matches with modules in %s.\n",
                      $self->carton->{path}, SUCCESS);
    }
}

sub cmd_update {
    # "cleanly" update distributions in extlib
    # rebuild the tree, update modules with DFS
    die <<EOF;
carton update is not implemented yet.

The command is supposed to update all the dependencies to the latest
version as if you don't have the current local environment doesn't
exist.

For now, you can remove the local environment and re-run carton install
to get the similar functionality.

EOF

}

sub cmd_exec {
    my($self, @args) = @_;

    my $system; # for unit testing
    my @include;
    $self->parse_options(\@args, 'I=s@', \@include, "system", \$system)
        or $self->error("Invalid option for 'exec', see 'carton help exec'.\n") and return;

    my $path = $self->carton->{path};
    my $lib  = join ",", @include, "$path/lib/perl5", ".";

    local $ENV{PERL5OPT} = "-Mlib::core::only -Mlib=$lib";
    local $ENV{PATH} = "$path/bin:$ENV{PATH}";

    $system ? system(@args) : exec(@args);
}

sub find_lock {
    my $self = shift;

    if (-e $self->lock_file) {
        return $self->lock_data; # TODO object
    }

    return;
}

sub lock_data {
    my $self = shift;

    my $lock;
    try {
        $lock = Carton::Util::load_json($self->lock_file);
    } catch {
        if (/No such file/) {
            $self->error("Can't locate carton.lock\n");
        } else {
            $self->error("Can't parse carton.lock: $_\n");
        }
    };

    return $lock;
}

sub lock_file {
    my $self = shift;
    return 'carton.lock';
}


1;
