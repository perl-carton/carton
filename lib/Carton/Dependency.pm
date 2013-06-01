package Carton::Dependency;
use strict;
use CPAN::Meta;
use Moo;

has meta => (is => 'ro', coerce => sub { CPAN::Meta->new($_[0], { lazy_validation => 1 }) });

sub distname {
    my $self = shift;
    sprintf '%s-%s', $self->meta->name, $self->meta->version;
}

1;
