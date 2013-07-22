package Carton::Error;
use strict;
use Exception::Class (
    'Carton::Error',
    'Carton::Error::CommandNotFound' => { isa => 'Carton::Error' },
    'Carton::Error::CommandExit' => { isa => 'Carton::Error', fields => [ 'code' ] },
    'Carton::Error::CPANfileNotFound' => { isa => 'Carton::Error' },
);

1;
