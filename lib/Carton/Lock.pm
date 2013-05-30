package Carton::Lock;
use strict;
use Carton::Package;

sub new {
    my($class, $data) = @_;
    bless $data, $class;
}

sub modules {
    values %{$_[0]->{modules} || {}};
}

sub packages {
    my $self = shift;

    my $index;
    while (my($name, $metadata) = each %{$self->{modules}}) {
        for my $mod (keys %{$metadata->{provides}}) {
            $index->{$mod} = { %{$metadata->{provides}{$mod}}, meta => $metadata };
        }
    }

    my @packages;
    for my $package (sort keys %$index) {
        my $module = $index->{$package};
        push @packages, Carton::Package->new($package, $module->{version}, $module->{meta}{pathname});
    }

    return @packages;
}

sub write_mirror_index {
    my($self, $file) = @_;

    my @packages = $self->packages;

    open my $fh, ">", $file or die $!;
    print $fh <<EOF;
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in carton.lock
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Carton $Carton::VERSION
Line-Count:   @{[ scalar(@packages) ]}
Last-Updated: @{[ scalar localtime ]}

EOF
    for my $p (@packages) {
        print $fh sprintf "%s %s  %s\n", pad($p->name, 32), pad($p->version || 'undef', 10, 1), $p->pathname;
    }
}

sub pad {
    my($str, $len, $left) = @_;

    my $howmany = $len - length($str);
    return $str if $howmany <= 0;

    my $pad = " " x $howmany;
    return $left ? "$pad$str" : "$str$pad";
}

1;
