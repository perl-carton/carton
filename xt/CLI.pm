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
use Carton::CLI;
use Capture::Tiny qw(capture);
use File::pushd ();
use Path::Tiny;

$Carton::CLI::UseSystem = 1;

use Class::Tiny qw( dir stdout stderr exit_code );

sub write_file {
    my($self, $file, @args) = @_;
    $self->dir->child($file)->spew(@args);
}

sub write_cpanfile {
    my($self, @args) = @_;
    $self->write_file(cpanfile => @args);
}

sub run_in_dir {
    my($self, $dir, @args) = @_;
    local $self->{dir} = $self->dir->child($dir);
    $self->run(@args);
}

sub run {
    my($self, @args) = @_;

    my $pushd = File::pushd::pushd $self->dir;

    my @capture = capture {
        my $code = eval { Carton::CLI->new->run(@args) };
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

