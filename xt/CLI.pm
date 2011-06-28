package xt::CLI;
use strict;
use base qw(Exporter);
our @EXPORT = qw(run cli);

use Test::Requires qw( Directory::Scratch );

sub cli {
    my $dir = Directory::Scratch->new();
    chdir $dir;

    my $app = Carton::CLI::Tested->new(dir => $dir);
    $app->config->set("mirror" => "$ENV{HOME}/minicpan");

    return $app;
}

sub run {
    my $app = cli();
    $app->run(@_);
    return $app;
}

package Carton::CLI::Tested;
use parent qw(Carton::CLI);

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
    my $self = shift;
    $self->{output} = '';
    $self->SUPER::run(@_);
}

sub output {
    my $self = shift;
    $self->{output};
}

1;

