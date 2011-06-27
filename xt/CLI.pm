package xt::CLI;
use strict;
use base qw(Exporter);
our @EXPORT = qw(run);

sub run {
    my $app = Carton::CLI::Tested->new;
    $app->run(@_);
    return $app;
}

package Carton::CLI::Tested;
use parent qw(Carton::CLI);

sub print {
    my $self = shift;
    $self->{output} .= $_[0];
}

sub output {
    my $self = shift;
    $self->{output};
}

1;

