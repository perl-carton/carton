package Carton::Error;
use strict;
use Exception::Class (
    'Carton::Error',
    'Carton::Error::CommandNotFound' => { isa => 'Carton::Error' },
    'Carton::Error::CommandExit' => { isa => 'Carton::Error', fields => [ 'code' ] },
    'Carton::Error::CPANfileNotFound' => { isa => 'Carton::Error' },
    'Carton::Error::SnapshotParseError' => { isa => 'Carton::Error', fields => [ 'path' ] },
    'Carton::Error::SnapshotNotFound' => { isa => 'Carton::Error', fields => [ 'path' ] },
);

1;
