package Carton::Environment;
use strict;
use Moo;

use Carton::Lockfile;
use Carton::Error;
use Path::Tiny;

has cpanfile => (is => 'rw');
has lockfile => (is => 'lazy');
has install_path => (is => 'lazy');
has vendor_cache  => (is => 'lazy');

sub _build_lockfile {
    my $self = shift;
    Carton::Lockfile->new($self->cpanfile->dirname . "/carton.lock");
}

sub _build_install_path {
    my $self = shift;
    if ($ENV{PERL_CARTON_PATH}) {
        return Path::Tiny->new($ENV{PERL_CARTON_PATH})->absolute;
    } else {
        return Path::Tiny->new($self->cpanfile->dirname . "/local");
    }
}

sub _build_vendor_cache {
    my $self = shift;
    Path::Tiny->new($self->install_path->dirname . "/vendor/cache");
}

sub build {
    my $class = shift;

    my $self = $class->new;

    if (my $cpanfile = $self->locate_cpanfile) {
        $self->cpanfile($cpanfile);
    } else {
        Carton::Error::CPANfileNotFound->throw(error => "Can't locate cpanfile");
    }

    $self;
}

sub locate_cpanfile {
    my $self = shift;

    my $current  = Path::Tiny->cwd;
    my $previous = '';

    until ($current eq '/' or $current eq $previous) {
        # TODO support PERL_CARTON_CPANFILE
        my $try = $current->child('cpanfile');
        if ($try->exists) {
            return $try->absolute;
        }

        ($previous, $current) = ($current, $current->parent);
    }

    return;
}

1;

