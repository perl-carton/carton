package Carton::Requirements;
use strict;
use Carton::Dependency;
use Moo;
use CPAN::Meta::Requirements;
use Module::CPANfile;

has lock => (is => 'ro');
has cpanfile => (is => 'ro', coerce => sub { Module::CPANfile->load($_[0]) });

sub walk_down {
    my($self, $cb) = @_;

    my $dumper; $dumper = sub {
        my($dependency, $prereqs, $level, $seen) = @_;

        $cb->($dependency, $level) if $dependency;

        my $reqs = CPAN::Meta::Requirements->new;
        $reqs->add_requirements($prereqs->requirements_for($_, 'requires'))
          for qw( configure build runtime test);

        for my $module (sort $reqs->required_modules) {
            my $dependency = $self->dependency_for($module, $reqs);
            if ($dependency->dist) {
                next if $seen->{$dependency->distname}++;
                $dumper->($dependency, $dependency->prereqs, $level + 1, $seen);
            } else {
                # no dist found in lock - probably core
            }
        }
    };

    $dumper->(undef, $self->cpanfile->prereqs, 0, {});
}

sub dependency_for {
    my($self, $module, $reqs) = @_;

    my $requirement = $reqs->requirements_for_module($module);

    my $dep = Carton::Dependency->new;
    $dep->module($module);
    $dep->requirement($requirement);

    if (my $dist = $self->lock->find($module)) {
        $dep->dist($dist);
    }

    return $dep;
}

1;


