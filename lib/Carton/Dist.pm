package Carton::Dist;
use Moo;
use warnings NONFATAL => 'all';
use CPAN::Meta;

has name     => (is => 'ro');
has pathname => (is => 'rw');
has provides => (is => 'rw', default => sub { +{} });
has requirements => (is => 'rw', lazy => 1, builder => 1,
                     handles => [ qw(add_string_requirement required_modules requirements_for_module) ]);

sub is_core { 0 }

sub distfile {
    my $self = shift;
    $self->pathname;
}

sub _build_requirements {
    CPAN::Meta::Requirements->new;
}

sub provides_module {
    my($self, $module) = @_;
    exists $self->provides->{$module};
}

sub version_for {
    my($self, $module) = @_;
    $self->provides->{$module}{version};
}

1;
