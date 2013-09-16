package Carton::CPANfile;
use Moo;
use warnings NONFATAL => 'all';
use Path::Tiny ();
use Module::CPANfile;

use overload q{""} => sub { $_[0]->stringify }, fallback => 1;

has path => (is => 'rw', coerce => sub { Path::Tiny->new($_[0]) }, handles => [ qw(stringify dirname) ]);
has _cpanfile => (is => 'rw', handles => [ qw(prereqs) ]);
has requirements => (is => 'rw', lazy => 1, builder => 1, handles => [ qw(required_modules requirements_for_module) ]);

sub load {
    my $self = shift;
    $self->_cpanfile( Module::CPANfile->load($self->path) );
}

sub _build_requirements {
    my $self = shift;
    my $reqs = CPAN::Meta::Requirements->new;
    $reqs->add_requirements($self->prereqs->requirements_for($_, 'requires'))
        for qw( configure build runtime test develop );
    $reqs->clear_requirement('perl');
    $reqs;
}

1;
