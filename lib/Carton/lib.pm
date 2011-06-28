package Carton::lib;
use strict;

# lib::core::only + additional paths

use Config;
sub import {
    my($class, @path) = @_;
    @INC = (@Config{qw(privlibexp archlibexp)}, @path);
    return;
}

1;

