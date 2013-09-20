package Carton::Dist::Specific;
use Moo;
use warnings NONFATAL => 'all';

use URI;
use File::Basename ();

has 'module' => (is => 'rw');
has 'requirement' => (is => 'rw');

sub provides {
    my $self = shift;
    return {
        $self->module => {
            version => $self->requirement->version, # FIXME version can be a Range
        },
    };
}

sub pathname {
    my $self = shift;
    my $uri = $self->requirement->git;
    $uri .= '@' . $self->requirement->ref if $self->requirement->ref;
    $uri;
}

1;
