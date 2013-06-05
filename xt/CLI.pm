package xt::CLI;
use strict;
use base qw(Exporter);
our @EXPORT = qw(run cli);

use Test::Requires qw( Capture::Tiny File::pushd );

sub cli {
    my $cli = Carton::CLI::Tested->new;
    $cli->dir( Path::Tiny->tempdir(CLEANUP => !$ENV{NO_CLEANUP}) );
    warn "Temp directory: ", $cli->dir, "\n" if $ENV{NO_CLEANUP};
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
has stdout => (is => 'rw');
has stderr => (is => 'rw');
has exit_code => (is => 'rw');

sub run {
    my($self, @args) = @_;

    my $pushd = File::pushd::pushd $self->dir;

    my @capture = capture {
        my $code = eval { $self->SUPER::run(@args) };
        $self->exit_code($@ ? 255 : $code);
    };

    $self->stdout($capture[0]);
    $self->stderr($capture[1]);
}

sub clean_local {
    my $self = shift;
    $self->dir->child("local")->remove_tree({ safe => 0 });
}

1;

