package Carton::Requirements;
use strict;
use Carton::Dependency;
use Moo;
use CPAN::Meta::Requirements;

has snapshot => (is => 'ro');
has requirements => (is => 'ro');
has all => (is => 'ro', default => sub { CPAN::Meta::Requirements->new });

sub walk_down {
    my($self, $cb) = @_;

    my $dumper; $dumper = sub {
        my($dependency, $reqs, $level, $parent) = @_;

        $cb->($dependency, $level) if $dependency;

        $self->all->add_requirements($reqs) unless $self->all->is_finalized;

        local $parent->{$dependency->distname} = 1 if $dependency;

        for my $module (sort $reqs->required_modules) {
            my $dependency = $self->dependency_for($module, $reqs);
            if ($dependency->dist) {
                next if $parent->{$dependency->distname};
                $dumper->($dependency, $dependency->requirements, $level + 1);
            } else {
                # no dist found in lock
            }
        }
    };

    $dumper->(undef, $self->requirements, 0, {});

    $self->all->clear_requirement('perl');
    $self->all->finalize;
}

sub dependency_for {
    my($self, $module, $reqs) = @_;

    my $requirement = $reqs->requirements_for_module($module);

    my $dep = Carton::Dependency->new;
    $dep->module($module);
    $dep->requirement($requirement);

    if (my $dist = $self->snapshot->find_or_core($module)) {
        $dep->dist($dist);
    }

    return $dep;
}

1;


