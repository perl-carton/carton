package xt::CLI;
use strict;
use base qw(Exporter);
our @EXPORT = qw(run cli);

use Test::Requires qw( Directory::Scratch Capture::Tiny File::pushd );

sub cli {
    my $cli = Carton::CLI::Tested->new;
    $cli->dir( Directory::Scratch->new(CLEANUP => !$ENV{NO_CLEANUP}) );
    $cli;
}

package Carton::CLI::Tested;
use Capture::Tiny qw(capture);
use File::pushd ();
use Path::Tiny;
use Moo;

extends 'Carton::CLI';
$Carton::CLI::UseSystem = 1;

has dir => (is => 'rw');

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
    Path::Tiny->new("$self->{dir}/local")->remove_tree({ safe => 0 });
}

1;

