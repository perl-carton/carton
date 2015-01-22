package Carton::Mirror;
use Moo;
use warnings NONFATAL => 'all';

our $DefaultMirror = 'http://cpan.metacpan.org/';
# set environmental variable to override, like so:
# PERL_CARTON_MIRROR=$PINTO_REPOSITORY_ROOT carton install
# see perldoc Carton::Doc::Install for further details

has url => (is => 'ro');

sub BUILDARGS {
    my($class, $url) = @_;
    return { url => $url };
}

sub default {
    my $class = shift;
    $class->new($DefaultMirror);
}

sub is_default {
    my $self = shift;
    $self->url eq $DefaultMirror;
}

1;

