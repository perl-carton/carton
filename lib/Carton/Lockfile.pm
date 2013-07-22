package Carton::Lockfile;
use strict;
use parent 'Path::Tiny';

sub new {
    my $class = shift;
    my $self = Path::Tiny->new(@_);
    bless $self, $class; # XXX: Path::Tiny doesn't allow subclasses. Should be via Role + handles?
}

sub load_if_exists {
    my $self = shift;
    Carton::Lock->from_file($self) if $self->exists;
}

sub load {
    my $self = shift;

    if ($self->exists) {
        Carton::Lock->from_file($self);
    } else {
        Carton::Error::LockfileNotFound->throw(
            error => "Can't find carton.lock: Run `carton install` to build the lock file.",
            path => $self->stringify,
        );
    }
}

1;

