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

use Carton;
use Carton::Builder;
use Carton::Mirror;
use Carton::Lock;
use Carton::Util;
use Carton::Error;
use Carton::Requirements;

use constant { SUCCESS => 0, INFO => 1, WARN => 2, ERROR => 3 };

our $UseSystem = 0; # 1 for unit testing

has verbose => (is => 'rw');
has carton  => (is => 'lazy');
has mirror  => (is => 'rw', builder => 1,
                coerce => sub { Carton::Mirror->new($_[0]) });

sub _build_mirror {
    my $self = shift;
    $ENV{PERL_CARTON_MIRROR} || $Carton::Mirror::DefaultMirror;
}

sub install_path {
    Path::Tiny->new($ENV{PERL_CARTON_PATH} || 'local')->absolute;
}

sub work_file {
    my($self, $file) = @_;
    my $wf = $self->install_path->child($file);
    $wf->parent->mkpath;
    $wf;
}

sub vendor_cache {
    Path::Tiny->new("vendor/cache")->absolute;
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
    my $call = $self->can("cmd_$cmd");

    my $code = try {
        $self->error("Could not find command '$cmd'\n")
            unless $call;
        $self->$call(@commands);
        return 0;
    } catch {
        ref =~ /Carton::Error::CommandExit/ and return 255;
        die $_;
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

    my $lock = $self->find_lock;
    my $cpanfile = $self->find_cpanfile;

    if ($lock) {
        $self->print("Bundling modules using $cpanfile\n");

        my $builder = Carton::Builder->new(
            mirror => $self->mirror,
        );
        $builder->bundle($self->install_path, $self->vendor_cache, $lock);
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

    if ($deployment && !$lock) {
        $self->error("--deployment requires carton.lock: Run `carton install` and make sure carton.lock is checked into your version control.\n");
    }

    my $cpanfile = $self->find_cpanfile;

    my $builder = Carton::Builder->new(
        cascade => 1,
        mirror => $self->mirror,
    );

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

    $builder->install($path);

    unless ($deployment) {
        my $prereqs = Module::CPANfile->load($cpanfile)->prereqs;
        Carton::Lock->build_from_local($path, $prereqs)->write($self->lock_file);
    }

    $self->print("Complete! Modules were installed into $path\n", SUCCESS);
}

sub cmd_show {
    my($self, @args) = @_;

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install`\n");

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

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install` to rebuild the lock file.\n");

    for my $dist ($lock->distributions) {
        $self->print($dist->$format . "\n");
    }
}

sub cmd_tree {
    my($self, @args) = @_;

    my $lock = $self->find_lock
      or $self->error("Can't find carton.lock: Run `carton install` to rebuild the lock file.\n");

    my $cpanfile = Module::CPANfile->load($self->find_cpanfile);
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

    my $lock = $self->find_lock
      or $self->error("Can't find carton.lock: Run `carton install` to rebuild the lock file.\n");

    my $prereqs = Module::CPANfile->load($self->find_cpanfile)->prereqs;

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

    my $cpanfile = Module::CPANfile->load($self->find_cpanfile);
    my $prereqs = $cpanfile->prereqs;

    my $reqs = CPAN::Meta::Requirements->new;
    $reqs->add_requirements($prereqs->requirements_for($_, 'requires'))
      for qw( configure build runtime test develop );

    @args = grep { $_ ne 'perl' } $reqs->required_modules unless @args;

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install` to build the lock file.\n");

    my @modules;
    for my $module (@args) {
        my $dist = $lock->find_or_core($module)
            or $self->error("Could not find module $module.\n");
        next if $dist->is_core;
        push @modules, "$module~" . $reqs->requirements_for_module($module);
    }

    my $builder = Carton::Builder->new(
        mirror => $self->mirror,
    );
    $builder->update($self->install_path, @modules);

    Carton::Lock->build_from_local($self->install_path, $prereqs)->write($self->lock_file);
}

sub cmd_exec {
    my($self, @args) = @_;

    my $lock = $self->find_lock
        or $self->error("Can't find carton.lock: Run `carton install` to build the lock file.\n");

    # allows -Ilib
    @args = map { /^(-[I])(.+)/ ? ($1,$2) : $_ } @args;

    $self->parse_options_pass_through(\@args, 'I=s@', sub { die "exec -Ilib is deprecated.\n" });

    unless (@args) {
        $self->error("carton exec needs a command to run.\n");
    }

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

sub index_file {
    my $self = shift;
    $self->work_file("cache/modules/02packages.details.txt");
}

1;
