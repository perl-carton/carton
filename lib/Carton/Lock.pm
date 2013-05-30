package Carton::Lock;

sub new {
    my($class, $data) = @_;
    bless $data, $class;
}

1;
