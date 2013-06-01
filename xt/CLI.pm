package xt::CLI;
use strict;
use base qw(Exporter);
our @EXPORT = qw(run cli);

use Test::Requires qw( Directory::Scratch Capture::Tiny File::pushd );

sub cli {
    my $dir = Directory::Scratch->new(CLEANUP => !$ENV{NO_CLEANUP});
    Carton::CLI::Tested->new(dir => $dir);
}

package Carton::CLI::Tested;
use parent qw(Carton::CLI);

$Carton::CLI::UseSystem = 1;

use Capture::Tiny qw(capture);
use File::pushd ();
use File::Path ();

sub new {
    my($class, %args) = @_;

    my $self = $class->SUPER::new;
    $self->{dir} = $args{dir};

    return $self;
}

sub dir {
    my $self = shift;
    $self->{dir};
}

sub print {
    my $self = shift;
    $self->{output} .= $_[0];
}

sub run {
    my($self, @args) = @_;
    my $pushd = File::pushd::pushd $self->{dir};
    $self->{output} = '';
    ($self->{system_output}, $self->{system_error}) = capture {
        eval { $self->SUPER::run(@args) };
    };
}

sub output {
    my $self = shift;
    $self->{output};
}

sub system_output {
    my $self = shift;
    $self->{system_output};
}

sub system_error {
    my $self = shift;
    $self->{system_error};
}

sub clean_local {
    my $self = shift;
    File::Path::rmtree("$self->{dir}/local", 1);
}

1;

