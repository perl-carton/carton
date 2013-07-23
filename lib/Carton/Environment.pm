package Carton::Environment;
use strict;
use Moo;

use Carton::Lockfile;
use Carton::Error;
use Path::Tiny;

has cpanfile => (is => 'rw');
has lockfile => (is => 'lazy');
has install_path => (is => 'rw', lazy => 1, builder => 1, coerce => sub { Path::Tiny->new($_[0])->absolute });
has vendor_cache  => (is => 'lazy');

sub _build_lockfile {
    my $self = shift;
    my $base = $self->cpanfile->basename eq 'cpanfile'
             ? 'carton.lock' : ("carton." . $self->cpanfile->basename . ".lock");
    Carton::Lockfile->new($self->cpanfile->dirname . "/$base");
}

sub _build_install_path {
    my $self = shift;
    if ($ENV{PERL_CARTON_PATH}) {
        return $ENV{PERL_CARTON_PATH};
    } else {
        return $self->cpanfile->dirname . "/local";
    }
}

sub _build_vendor_cache {
    my $self = shift;
    Path::Tiny->new($self->install_path->dirname . "/vendor/cache");
}

sub build_with {
    my($class, $cpanfile) = @_;

    $cpanfile = Path::Tiny->new($cpanfile)->absolute;
    if ($cpanfile->is_file) {
        return $class->new(cpanfile => $cpanfile);
    } else {
        Carton::Error::CPANfileNotFound->throw(error => "Can't locate cpanfile: $cpanfile");
    }
}

sub build {
    my($class, $cpanfile_path, $install_path) = @_;

    my $self = $class->new;

    $cpanfile_path &&= Path::Tiny->new($cpanfile_path)->absolute;

    my $cpanfile = $self->locate_cpanfile($cpanfile_path || $ENV{PERL_CARTON_CPANFILE});
    if ($cpanfile && $cpanfile->is_file) {
        $self->cpanfile($cpanfile);
    } else {
        Carton::Error::CPANfileNotFound->throw(error => "Can't locate cpanfile: (@{[ $cpanfile_path || 'cpanfile' ]})");
    }

    $self->install_path($install_path) if $install_path;

    $self;
}

sub locate_cpanfile {
    my($self, $path) = @_;

    if ($path) {
        return Path::Tiny->new($path)->absolute;
    }

    my $current  = Path::Tiny->cwd;
    my $previous = '';

    until ($current eq '/' or $current eq $previous) {
        # TODO support PERL_CARTON_CPANFILE
        my $try = $current->child('cpanfile');
        if ($try->is_file) {
            return $try->absolute;
        }

        ($previous, $current) = ($current, $current->parent);
    }

    return;
}

1;

