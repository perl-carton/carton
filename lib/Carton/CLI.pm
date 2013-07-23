package Carton::CLI;
use strict;
use warnings;

use Config;
use Getopt::Long;
use Module::CPANfile;
use Path::Tiny;
use Try::Tiny;
use Moo;
use Module::CoreList;
use Scalar::Util qw(blessed);

use Carton;
use Carton::Builder;
use Carton::Mirror;
use Carton::Lock;
use Carton::Util;
use Carton::Environment;
use Carton::Error;
use Carton::Requirements;

use constant { SUCCESS => 0, INFO => 1, WARN => 2, ERROR => 3 };

our $UseSystem = 0; # 1 for unit testing

has verbose => (is => 'rw');
has carton  => (is => 'lazy');
has mirror  => (is => 'rw', builder => 1,
                coerce => sub { Carton::Mirror->new($_[0]) });
has environment => (is => 'rw', builder => 1, lazy => 1,
                    handles => [ qw( cpanfile lockfile install_path vendor_cache )]);

sub _build_mirror {
    my $self = shift;
    $ENV{PERL_CARTON_MIRROR} || $Carton::Mirror::DefaultMirror;
}

sub _build_environment {
    Carton::Environment->build;
}

sub work_file {
    my($self, $file) = @_;
    my $wf = $self->install_path->child($file);
    $wf->parent->mkpath;
    $wf;
}

sub run {
    my($self, @args) = @_;

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

    my $code = try {
        my $call = $self->can("cmd_$cmd")
          or Carton::Error::CommandNotFound->throw(error => "Could not find command '$cmd'");
        $self->$call(@commands);
        return 0;
    } catch {
        die $_ unless blessed $_ && $_->can('rethrow');

        if ($_->isa('Carton::Error::CommandExit')) {
            return $_->code || 255;
        } elsif ($_->isa('Carton::Error')) {
            warn $_->error, "\n";
            return 255;
        }
    };

    return $code;
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

    my $lock = $self->lockfile->load;
    my $cpanfile = $self->cpanfile;

    $self->print("Bundling modules using $cpanfile\n");

    my $builder = Carton::Builder->new(
        mirror => $self->mirror,
        cpanfile => $self->cpanfile,
    );
    $builder->bundle($self->install_path, $self->vendor_cache, $lock);

    $self->printf("Complete! Modules were bundled into %s\n", $self->vendor_cache, SUCCESS);
}

sub cmd_install {
    my($self, @args) = @_;

    my($install_path, $cpanfile_path, @without);

    $self->parse_options(
        \@args,
        "p|path=s"    => \$install_path,
        "cpanfile=s"  => \$cpanfile_path,
        "without=s"   => sub { push @without, split /,/, $_[1] },
        "deployment!" => \my $deployment,
        "cached!"     => \my $cached,
    );

    my $environment = Carton::Environment->build($cpanfile_path, $install_path);
    $self->environment($environment);

    my $lock = $self->lockfile->load_if_exists;

    if ($deployment && !$lock) {
        $self->error("--deployment requires carton.lock: Run `carton install` and make sure carton.lock is checked into your version control.\n");
    }

    my $cpanfile = $self->cpanfile;

    my $builder = Carton::Builder->new(
        cascade => 1,
        mirror  => $self->mirror,
        without => \@without,
        cpanfile => $self->cpanfile,
    );

    # TODO: --without with no .lock won't fetch the groups, resulting in insufficient requirements

    if ($deployment) {
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

    $builder->install($self->install_path);

    unless ($deployment) {
        my $prereqs = Module::CPANfile->load($cpanfile)->prereqs;
        Carton::Lock->build_from_local($self->install_path, $prereqs)->write($self->lockfile);
    }

    $self->print("Complete! Modules were installed into @{[$self->install_path]}\n", SUCCESS);
}

sub cmd_show {
    my($self, @args) = @_;

    my $lock = $self->lockfile->load;

    for my $module (@args) {
        my $dist = $lock->find($module)
            or $self->error("Couldn't locate $module in carton.lock\n");
        $self->print( $dist->dist . "\n" );
    }
}

sub cmd_list {
    my($self, @args) = @_;

    my $format = 'dist';

    $self->parse_options(
        \@args,
        "distfile" => sub { $format = 'distfile' },
    );

    my $lock = $self->lockfile->load;

    for my $dist ($lock->distributions) {
        $self->print($dist->$format . "\n");
    }
}

sub cmd_tree {
    my($self, @args) = @_;

    my $lock = $self->lockfile->load;

    my $cpanfile = Module::CPANfile->load($self->cpanfile);
    my $requirements = Carton::Requirements->new(lock => $lock, prereqs => $cpanfile->prereqs);

    my %seen;
    my $dumper = sub {
        my($dependency, $level) = @_;
        return if $dependency->dist->is_core;
        return if $seen{$dependency->distname}++;
        $self->printf( "%s%s (%s)\n", " " x ($level - 1), $dependency->module, $dependency->distname, INFO );
    };
    $requirements->walk_down($dumper);
}

sub cmd_check {
    my($self, @args) = @_;

    my $cpanfile_path;
    $self->parse_options(
        \@args,
        "cpanfile=s"  => \$cpanfile_path,
    );

    my $environment = Carton::Environment->build($cpanfile_path);
    $self->environment($environment);

    my $lock = $self->lockfile->load;

    my $prereqs = Module::CPANfile->load($self->cpanfile)->prereqs;

    # TODO remove $lock
    # TODO pass git spec to Requirements?
    my $requirements = Carton::Requirements->new(lock => $lock, prereqs => $prereqs);
    $requirements->walk_down(sub { });

    my @missing;
    for my $module ($requirements->all->required_modules) {
        my $install = $lock->find_or_core($module);
        if ($install) {
            unless ($requirements->all->accepts_module($module => $install->version)) {
                push @missing, [ $module, 1, $install->version ];
            }
        } else {
            push @missing, [ $module, 0 ];
        }
    }

    if (@missing) {
        $self->print("Following dependencies are not satisfied.\n", INFO);
        for my $missing (@missing) {
            my($module, $unsatisfied, $version) = @$missing;
            if ($unsatisfied) {
                $self->printf("  %s has version %s. Needs %s\n",
                              $module, $version, $requirements->all->requirements_for_module($module), INFO);
            } else {
                $self->printf("  %s is not installed. Needs %s\n",
                              $module, $requirements->all->requiements_for_module($module), INFO);
            }
        }
        $self->printf("Run `carton install` to install them.\n", INFO);
        Carton::Error::CommandExit->throw;
    } else {
        $self->print("cpanfile's dependencies are satisfied.\n", INFO);
    }
}

sub cmd_update {
    my($self, @args) = @_;

    my $cpanfile = Module::CPANfile->load($self->cpanfile);
    my $prereqs = $cpanfile->prereqs;

    my $reqs = CPAN::Meta::Requirements->new;
    $reqs->add_requirements($prereqs->requirements_for($_, 'requires'))
      for qw( configure build runtime test develop );

    @args = grep { $_ ne 'perl' } $reqs->required_modules unless @args;

    my $lock = $self->lockfile->load;

    my @modules;
    for my $module (@args) {
        my $dist = $lock->find_or_core($module)
            or $self->error("Could not find module $module.\n");
        next if $dist->is_core;
        push @modules, "$module~" . $reqs->requirements_for_module($module);
    }

    my $builder = Carton::Builder->new(
        mirror => $self->mirror,
        cpanfile => $self->cpanfile,
    );
    $builder->update($self->install_path, @modules);

    Carton::Lock->build_from_local($self->install_path, $prereqs)->write($self->lockfile);
}

sub cmd_exec {
    my($self, @args) = @_;

    my $lock = $self->lockfile->load;

    # allows -Ilib
    @args = map { /^(-[I])(.+)/ ? ($1,$2) : $_ } @args;

    while (@args) {
        if ($args[0] eq '-I') {
            warn "exec -Ilib is deprecated. Just run the following command with -I.\n";
            splice(@args, 0, 2);
        } else {
            last;
        }
    }

    $self->parse_options_pass_through(\@args); # to handle --

    unless (@args) {
        $self->error("carton exec needs a command to run.\n");
    }

    # PERL5LIB takes care of arch
    my $path = $self->install_path;
    local $ENV{PERL5LIB} = "$path/lib/perl5";
    local $ENV{PATH} = "$path/bin:$ENV{PATH}";

    $UseSystem ? system(@args) : exec(@args);
}

sub index_file {
    my $self = shift;
    $self->work_file("cache/modules/02packages.details.txt");
}

1;
