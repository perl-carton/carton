package Carton::Dependency;
use strict;
use CPAN::Meta;
use Moo;

has name     => (is => 'ro');
has pathname => (is => 'ro');
has provides => (is => 'ro');
has version  => (is => 'ro');
has target   => (is => 'ro');
has dist     => (is => 'ro');
has mymeta   => (is => 'ro', coerce => sub { CPAN::Meta->new($_[0], { lazy_validation => 1 }) });

sub distfile {
    my $self = shift;
    $self->pathname;
}

sub prereqs {
    my $self = shift;
    $self->mymeta->effective_prereqs;
}

1;
