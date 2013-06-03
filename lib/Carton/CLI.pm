package Carton::CLI;
use strict;
use warnings;

use Cwd;
use Config;
use Getopt::Long;

use Carton;
use Carton::Builder;
use Carton::Mirror;
use Carton::Lock;
use Carton::Util;
use Carton::Error;
use Scalar::Util;
use Try::Tiny;
use Moo;

use Module::CPANfile;
use CPAN::Meta::Requirements;

use constant { SUCCESS => 0, INFO => 1, WARN => 2, ERROR => 3 };

our $UseSystem = 0; # 1 for unit testing

has verbose => (is => 'rw');
has carton  => (is => 'lazy');
has workdir => (is => 'lazy');
has mirror  => (is => 'rw', builder => 1,
                coerce => sub { Carton::Mirror->new($_[0]) });

sub _build_workdir {
    my $self = shift;
    $ENV{PERL_CARTON_HOME} || (Cwd::cwd() . "/.carton");
}

sub _build_mirror {
    my $self = shift;
    $ENV{PERL_CARTON_MIRROR} || $Carton::Mirror::DefaultMirror;
}

sub install_path {
    $ENV{PERL_CARTON_PATH} || File::Spec->rel2abs('local');
}

sub vendor_cache {
    File::Spec->rel2abs("vendor/cache");
}

sub run {
    my($self, @args) = @_;

    my $dir = $self->workdir;
    mkdir $dir, 0777 unless -e $dir;

    my @commands;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_ignore_case", "pass_through" ],
    );
    $p->getoptionsfromarray(
        \@args,
        "h|help"    => sub { unshift @commands, 'help' },
        "v|version" => sub { unshift @commands, 'version' },
        "verbose!"  => sub { $self->verbose($_[1]) },
    );

    push @commands, @args;

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

sub parse_options {
    my($self, $args, @spec) = @_;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_auto_abbrev", "no_ignore_case" ],
    );
    $p->getoptionsfromarray($args, @spec);
}

sub parse_options_pass_through {
    my($self, $args, @spec) = @_;

    my $p = Getopt::Long::Parser->new(
        config => [ "no_auto_abbrev", "no_ignore_case", "pass_through" ],
    );
    $p->getoptionsfromarray($args, @spec);

    # with pass_through keeps -- in args
    shift @$args if $args->[0] && $args->[0] eq '--';
}

sub printf {
    my $self = shift;
    my $type = pop;
    my($temp, @args) = @_;
    $self->print(sprintf($temp, @args), $type);
}

sub print {
    my($self, $msg, $type) = @_;
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

    my $lock = $self->find_lock;
    my $cpanfile = $self->find_cpanfile;

    if ($lock) {
        $self->print("Bundling modules using $cpanfile\n");

        my $index = $self->index_file;
        $lock->write_index($index);

        my $builder = Carton::Builder->new(
            mirror => $self->mirror,
            index  => $index,
        );
        $builder->bundle($self->vendor_cache);
    } else {
        $self->error("Can't locate carton.lock file. Run carton install first\n");
    }

    $self->printf("Complete! Modules were bundled into %s\n", $self->vendor_cache, SUCCESS);
}

sub cmd_install {
    my($self, @args) = @_;

    my $path = $self->install_path;

    $self->parse_options(
        \@args,
        "p|path=s"    => \$path,
        "deployment!" => \my $deployment,
        "cached!"     => \my $cached,
    );

    my $lock = $self->find_lock;
    my $cpanfile = $self->find_cpanfile;

    my $builder = Carton::Builder->new(
        cascade => 1,
        mirror => $self->mirror,
    );

    if ($deployment) {
        unless ($lock) {
            $self->error("--deployment requires carton.lock: Run `carton install` and make sure carton.lock is checked into your version control.\n"); # TODO test
        }
        $self->print("Installing modules using $cpanfile (deployment mode)\n");
        $builder->cascade(0);
    } else {
        $self->print("Installing modules using $cpanfile\n");
    }

    # TODO merge CPANfile git to mirror even if lock doesn't exist
    if ($lock) {
        $lock->write_index($self->index_file);
        $builder->index($self->index_file);
    }

    if ($cached) {
        $builder->mirror(Carton::Mirror->new($self->vendor_cache));
    }

    $builder->install($path);

    unless ($deployment) {
        Carton::Lock->build_from_local($path)->write($self->lock_file);
    }

    $self->print("Complete! Modules were installed into $path\n", SUCCESS);
}

sub cmd_show {
    my($self, @args) = @_;

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install`\n");

    for my $module (@args) {
        my $dependency = $lock->find($module)
            or $self->error("Couldn't locate $module in carton.lock\n");
        $self->print( $dependency->dist . "\n" );
    }
}

sub cmd_list {
    my($self, @args) = @_;

    my $format = 'dist';

    $self->parse_options(
        \@args,
        "distfile" => sub { $format = 'distfile' },
    );

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install` to rebuild the lock file.\n");

    for my $dependency ($lock->dependencies) {
        $self->print($dependency->$format . "\n");
    }
}

sub cmd_tree {
    my($self, @args) = @_;

    my $lock = $self->find_lock
      or $self->error("Can't find carton.lock: Run `carton install` to rebuild the lock file.\n");

    my $cpanfile = Module::CPANfile->load($self->find_cpanfile);
    my $prereqs = $cpanfile->prereqs;

    my $level = 0;
    $self->dump_tree($lock, undef, $prereqs, $level);
}

sub dump_tree {
    my($self, $lock, $name, $prereqs, $level) = @_;

    my $req = CPAN::Meta::Requirements->new;
    $req->add_requirements($prereqs->requirements_for($_, 'requires'))
      for qw( configure build runtime test);

    if ($name) {
        $self->print( (" " x ($level - 1)) . "$name\n" );
    }

    my $requirements = $req->as_string_hash;
    while (my($module, $version) = each %$requirements) {
        if (my $dependency = $lock->find($module)) {
            $self->dump_tree($lock, $dependency->dist, $dependency->prereqs, $level + 1);
        } else {
            # TODO: probably core, what if otherwise?
        }
    }
}

sub cmd_check {
    my($self, @args) = @_;
    die <<EOF;
carton check is not implemented yet.
EOF
}

sub cmd_update {
    # "cleanly" update distributions in extlib
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

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install` to build the lock file.\n");

    # allows -Ilib
    @args = map { /^(-[I])(.+)/ ? ($1,$2) : $_ } @args;

    $self->parse_options_pass_through(\@args, 'I=s@', sub { die "exec -Ilib is deprecated.\n" });

    # PERL5LIB takes care of arch
    my $path = $self->install_path;
    local $ENV{PERL5LIB} = "$path/lib/perl5";
    local $ENV{PATH} = "$path/bin:$ENV{PATH}";

    $UseSystem ? system(@args) : exec(@args);
}

sub find_cpanfile {
    my $self = shift;

    if (-e 'cpanfile') {
        return 'cpanfile';
    } else {
        $self->error("Can't locate cpanfile\n");
    }
}

sub find_lock {
    my $self = shift;

    if (-e $self->lock_file) {
        my $lock;
        try {
            $lock = Carton::Lock->from_file($self->lock_file);
        } catch {
            $self->error("Can't parse carton.lock: $_\n");
        };

        return $lock;
    }

    return;
}

sub lock_file {
    my $self = shift;
    return 'carton.lock';
}

sub work_file {
    my($self, $file) = @_;
    return join "/", $self->workdir, $file;
}

sub index_file {
    my $self = shift;
    $self->work_file("02packages.details.txt");
}

1;
