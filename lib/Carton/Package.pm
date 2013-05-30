package Carton::Package;
use strict;

sub new {
    my($class, $name, $version, $pathname) = @_;
    bless {
        name => $name,
        version => $version,
        pathname => $pathname,
    }, $class;
}

sub name     { $_[0]->{name} }
sub version  { $_[0]->{version} }
sub pathname { $_[0]->{pathname} }

1;


