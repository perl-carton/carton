package Carton::Dist;
use strict;
use CPAN::Meta;
use Moo;

# XXX name here means the name of main module
# XXX dist means the name of dist
has name     => (is => 'ro');
has pathname => (is => 'ro');
has provides => (is => 'ro');
has version  => (is => 'ro');
has target   => (is => 'ro');
has dist     => (is => 'ro');
has mymeta   => (is => 'ro', coerce => sub { CPAN::Meta->new($_[0], { lazy_validation => 1 }) });

sub is_core { 0 }

sub distfile {
    my $self = shift;
    $self->pathname;
}

sub prereqs {
    my $self = shift;
    $self->mymeta->effective_prereqs;
}

1;
