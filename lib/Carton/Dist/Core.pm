package Carton::Dist::Core;
use strict;
use Moo;
extends 'Carton::Dist';

sub BUILDARGS {
    my($class, %args) = @_;

    $args{name} = "perl-$]";

    \%args;
}

sub is_core { 1 }

sub version_for {
    my($self, $module) = @_;
    $self->version;
}

1;
