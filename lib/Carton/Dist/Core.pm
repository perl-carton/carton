package Carton::Dist::Core;
use strict;
use Moo;
extends 'Carton::Dist';

sub BUILDARGS {
    my($class, %args) = @_;

    $args{dist} = "perl-$]";

    \%args;
}

sub is_core { 1 }

sub prereqs {
    my $self = shift;
    CPAN::Meta::Prereqs->new;
}

1;
