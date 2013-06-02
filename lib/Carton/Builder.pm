package Carton::Builder;
use strict;
use File::Temp;
use Moo;

has mirror  => (is => 'rw');
has index   => (is => 'rw');
has cascade => (is => 'rw', default => sub { 1 });

sub effective_mirrors {
    my $self = shift;

    # push default CPAN mirror always, as a fallback
    # TODO don't pass fallback if --cached is set?

    my @mirrors = ($self->mirror);
    push @mirrors, Carton::Mirror->default if $self->use_darkpan;
    push @mirrors, Carton::Mirror->new('http://backpan.perl.org/');

    @mirrors;
}

sub use_darkpan {
    my $self = shift;
    ! $self->mirror->is_default;
}

sub bundle {
    my($self, $path) = @_;

    my $temp = File::Temp::tempdir(CLEANUP => 1); # ignore installed

    $self->run_cpanm(
        "-L", $temp,
        (map { ("--mirror", $_->url) } $self->effective_mirrors),
        "--mirror-index", $self->index,
        "--skip-satisfied",
        "--save-dists", $path,
        "--with-develop",
        "--installdeps", ".",
    );
}

sub install {
    my($self, $path) = @_;

    $self->run_cpanm(
        "-L", $path,
        (map { ("--mirror", $_->url) } $self->effective_mirrors),
        "--skip-satisfied",
        ( $self->index ? ("--mirror-index", $self->index) : () ),
        ( $self->cascade ? "--cascade-search" : () ),
        ( $self->use_darkpan ? "--mirror-only" : () ),
        "--with-develop",
        "--installdeps", ".",
    ) or die "Installing modules failed\n";
}

sub run_cpanm {
    my($self, @args) = @_;
    local $ENV{PERL_CPANM_OPT};
    !system "cpanm", "--quiet", "--notest", @args;
}

1;
