package Carton::Dependency;
use strict;
use Moo;

has module => (is => 'rw');
has requirement => (is => 'rw');
has dist => (is => 'rw', handles => [ qw(requirements) ]);

sub distname {
    my $self = shift;
    $self->dist->name;
}

sub version {
    my $self = shift;
    $self->dist->version_for($self->module);
}

1;
