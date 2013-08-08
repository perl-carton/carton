package Carton::Dist::Core;
use strict;
use Moo;
extends 'Carton::Dist';

has module_version => (is => 'ro');

sub BUILDARGS {
    my($class, %args) = @_;

    # TODO represent dual-life
    $args{name} =~ s/::/-/g;

    \%args;
}

sub is_core { 1 }

sub version_for {
    my($self, $module) = @_;
    $self->module_version;
}

1;
