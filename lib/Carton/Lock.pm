package Carton::Lock;
use strict;
use Config;
use Carton::Dependency;
use Carton::Package;
use Carton::Index;
use Carton::Util;
use CPAN::Meta;
use File::Find ();
use Moo;

has version => (is => 'ro');
has modules => (is => 'ro', default => sub { +{} });

use constant CARTON_LOCK_VERSION => '0.9';

sub from_file {
    my($class, $file) = @_;

    my $data = Carton::Util::load_json($file);
    return $class->new($data);
}

sub write {
    my($self, $file) = @_;
    Carton::Util::dump_json({ %$self }, $file);
}

sub dependencies {
    map Carton::Dependency->new(meta => $_->{mymeta}),
      values %{$_[0]->modules}
}

sub find {
    my($self, $module) = @_;
    $self->modules->{$module};
}

sub index {
    my $self = shift;

    my $index = Carton::Index->new;
    for my $package ($self->packages) {
        $index->add_package($package);
    }

    return $index;
}

sub packages {
    my $self = shift;

    my @packages;
    while (my($name, $metadata) = each %{$self->modules}) {
        while (my($package, $provides) = each %{$metadata->{provides}}) {
            # TODO what if duplicates?
            push @packages, Carton::Package->new($package, $provides->{version}, $metadata->{pathname});
        }
    }

    return @packages;
}

sub write_index {
    my($self, $file) = @_;

    open my $fh, ">", $file or die $!;
    $self->index->write($fh);
}

sub build_from_local {
    my($class, $path) = @_;

    my %installs = $class->find_installs($path);

    return $class->new(
        modules => \%installs,
        version => CARTON_LOCK_VERSION,
    );
}

sub find_installs {
    my($class, $path) = @_;

    my $libdir = "$path/lib/perl5/$Config{archname}/.meta";
    return unless -e $libdir;

    my @installs;
    my $wanted = sub {
        if ($_ eq 'install.json') {
            push @installs, [ $File::Find::name, "$File::Find::dir/MYMETA.json" ];
        }
    };
    File::Find::find($wanted, $libdir);

    return map {
        my $module = Carton::Util::load_json($_->[0]);
        my $mymeta = -f $_->[1] ? CPAN::Meta->load_file($_->[1])->as_struct({ version => "2" }) : {};
        ($module->{name} => { %$module, mymeta => $mymeta }) } @installs;
}

1;
