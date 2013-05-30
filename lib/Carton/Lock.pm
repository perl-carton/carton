package Carton::Lock;
use strict;
use Carton::Package;
use Carton::Index;
use Carton::Util;

sub from_file {
    my($class, $file) = @_;

    my $data = Carton::Util::load_json($file);
    return $class->new($data);
}

sub new {
    my($class, $data) = @_;
    bless $data, $class;
}

sub write {
    my($self, $file) = @_;
    Carton::Util::dump_json({ %$self }, $file);
}

sub modules {
    values %{$_[0]->{modules} || {}};
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
    while (my($name, $metadata) = each %{$self->{modules}}) {
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

1;
