package Carton::Tree;
use strict;
use Carton::Dependency;
use Moo;

has cpanfile => (is => 'ro');
has snapshot => (is => 'ro');

sub walk_down {
    my($self, $cb) = @_;

    my $dumper; $dumper = sub {
        my($dependency, $reqs, $level, $parent) = @_;

        $cb->($dependency, $reqs, $level);
        local $parent->{$dependency->distname} = 1 if $dependency;

        for my $module (sort $reqs->required_modules) {
            my $dependency = $self->dependency_for($module, $reqs);
            if ($dependency->dist) {
                next if $parent->{$dependency->distname};
                $dumper->($dependency, $dependency->requirements, $level + 1, $parent);
            } else {
                # no dist found in lock
            }
        }
    };

    $dumper->(undef, $self->cpanfile->requirements, 0, {});
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

sub merged_requirements {
    my $self = shift;

    my $merged_reqs = CPAN::Meta::Requirements->new;
    $self->walk_down(sub {
        my($dependency, $reqs, $level) = @_;
        $merged_reqs->add_requirements($reqs);
    });

    $merged_reqs->clear_requirement('perl');
    $merged_reqs->finalize;

    $merged_reqs;
}

1;
