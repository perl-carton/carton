package Carton::Dist::Specific;
use Moo;
use warnings NONFATAL => 'all';

use URI;
use File::Basename ();

has 'module' => (is => 'rw');
has 'requirement' => (is => 'rw', handles => ['options']);

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

    if (my $git = $self->options->{git}) {
        $git .= '@' . $self->options->{ref} if $self->options->{ref};
        return $git;
    } elsif ($self->options->{dist}) {
        return $self->options->{dist};
    }
}

1;
