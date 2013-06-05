package Carton::Builder;
use strict;
use Moo;

has mirror  => (is => 'rw');
has index   => (is => 'rw');
has cascade => (is => 'rw', default => sub { 1 });

sub effective_mirrors {
    my $self = shift;

    # push default CPAN mirror always, as a fallback
    # TODO don't pass fallback if --cached is set?

    my @mirrors = ($self->mirror);
    push @mirrors, Carton::Mirror->default if $self->custom_mirror;
    push @mirrors, Carton::Mirror->new('http://backpan.perl.org/');

    @mirrors;
}

sub custom_mirror {
    my $self = shift;
    ! $self->mirror->is_default;
}

sub bundle {
    my($self, $path, $cache_path, $lock) = @_;

    for my $dist ($lock->distributions) {
        my $source = $path->child("cache/authors/id/" . $dist->pathname);
        my $target = $cache_path->child("authors/id/" . $dist->pathname);

        if ($source->exists) {
            warn "Copying ", $dist->pathname, "\n";
            $target->parent->mkpath;
            $source->copy($target) or warn "$target: $!";
        } else {
            warn "Couldn't find @{[ $dist->pathname ]}\n";
        }
    }
}

sub install {
    my($self, $path) = @_;

    $self->run_cpanm(
        "-L", $path,
        (map { ("--mirror", $_->url) } $self->effective_mirrors),
        ( $self->index ? ("--mirror-index", $self->index) : () ),
        ( $self->cascade ? "--cascade-search" : () ),
        ( $self->custom_mirror ? "--mirror-only" : () ),
        "--save-dists", "$path/cache",
        "--with-develop",
        "--installdeps", ".",
    ) or die "Installing modules failed\n";
}

sub update {
    my($self, $path, @modules) = @_;

    $self->run_cpanm(
        "-L", $path,
        (map { ("--mirror", $_->url) } $self->effective_mirrors),
        ( $self->custom_mirror ? "--mirror-only" : () ),
        "--save-dists", "$path/cache",
        @modules
    ) or die "Updating modules failed\n";
}

sub run_cpanm {
    my($self, @args) = @_;
    local $ENV{PERL_CPANM_OPT};
    !system "cpanm", "--quiet", "--notest", @args;
}

1;
