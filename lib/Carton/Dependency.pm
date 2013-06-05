package Carton::Dependency;
use strict;
use Moo;

has module => (is => 'rw');
has requirement => (is => 'rw');
has dist => (is => 'rw', handles => [ qw(prereqs) ]);

sub distname {
    my $self = shift;
    $self->dist->dist;
}

sub version {
    my $self = shift;
    $self->dist->provides->{$self->module}{version};
}

1;
