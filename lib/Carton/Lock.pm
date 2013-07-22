package Carton::Lock;
use strict;
use Config;
use Carton::Dist;
use Carton::Dist::Core;
use Carton::Error;
use Carton::Package;
use Carton::Index;
use Carton::Util;
use CPAN::Meta;
use CPAN::Meta::Requirements;
use File::Find ();
use Try::Tiny;
use Module::CoreList;
use Moo;

has version => (is => 'ro');
has modules => (is => 'ro', default => sub { +{} });

use constant CARTON_LOCK_VERSION => '0.9';

sub from_file {
    my($class, $file) = @_;

    my $data = try { Carton::Util::load_json($file) }
        catch { Carton::Error::LockfileParseError->throw(error => "Can't parse carton.lock", path => $file) };

    return $class->new($data);
}

sub write {
    my($self, $file) = @_;
    Carton::Util::dump_json({ %$self }, $file);
}

sub distributions {
    map Carton::Dist->new($_), values %{$_[0]->modules}
}

sub find {
    my($self, $module) = @_;

    for my $meta (values %{$_[0]->modules}) {
        if ($meta->{provides}{$module}) {
            return Carton::Dist->new( $self->modules->{$meta->{name}} );
        }
    }

    return;
}

sub find_or_core {
    my($self, $module) = @_;
    $self->find($module) || $self->find_in_core($module);
}

sub find_in_core {
    my($self, $module) = @_;

    if (exists $Module::CoreList::version{$]}{$module}) {
        my $version = $Module::CoreList::version{$]}{$module}; # maybe undef
        return Carton::Dist::Core->new(name => $module, version => $version);
    }

    return;
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
    my($class, $path, $prereqs) = @_;

    my $installs = $class->find_installs($path, $prereqs);

    return $class->new(
        modules => $installs,
        version => CARTON_LOCK_VERSION,
    );
}

sub find_installs {
    my($class, $path, $prereqs) = @_;

    my $libdir = "$path/lib/perl5/$Config{archname}/.meta";
    return {} unless -e $libdir;

    my $reqs = CPAN::Meta::Requirements->new;
    $reqs->add_requirements($prereqs->requirements_for($_, 'requires'))
      for qw( configure build runtime test develop );

    my @installs;
    my $wanted = sub {
        if ($_ eq 'install.json') {
            push @installs, [ $File::Find::name, "$File::Find::dir/MYMETA.json" ];
        }
    };
    File::Find::find($wanted, $libdir);

    my %installs;
    for my $file (@installs) {
        my $module = Carton::Util::load_json($file->[0]);
        my $mymeta = -f $file->[1] ? CPAN::Meta->load_file($file->[1])->as_struct({ version => "2" }) : {};
        if ($reqs->accepts_module($module->{name}, $module->{provides}{$module->{name}}{version})) {
            if (my $exist = $installs{$module->{name}}) {
                my $old_ver = version->new($exist->{provides}{$module->{name}}{version});
                my $new_ver = version->new($module->{provides}{$module->{name}}{version});
                if ($new_ver >= $old_ver) {
                    $installs{ $module->{name} } = { %$module, mymeta => $mymeta };
                } else {
                    # Ignore same distributions older than the one we have
                }
            } else {
                $installs{ $module->{name} } = { %$module, mymeta => $mymeta };
            }
        } else {
            # Ignore installs because cpanfile doesn't accept it
        }
    }

    return \%installs;
}

1;
