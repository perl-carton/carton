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
has output => (is => 'rw');
has system_output => (is => 'rw');
has system_error  => (is => 'rw');

sub print {
    my $self = shift;
    $self->{output} .= $_[0];
}

sub run {
    my($self, @args) = @_;

    my $pushd = File::pushd::pushd $self->dir;

    $self->{output} = '';

    my @capture = capture {
        eval { $self->SUPER::run(@args) };
    };

    $self->system_output($capture[0]);
    $self->system_error($capture[1]);
}

sub clean_local {
    my $self = shift;
    Path::Tiny->new("$self->{dir}/local")->remove_tree({ safe => 0 });
}

1;

