package Carton::Error;
use strict;
use version; our $VERSION = version->declare("v0.9.12");
use Exception::Class (
    'Carton::Error::CommandExit',
);


1;
