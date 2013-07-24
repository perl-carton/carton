package Carton::Lockfile::Emitter;
use strict;
use Moo;

sub emit {
    my($self, $lockfile) = @_;

    my $data = '';
    $data .= "# carton snapshot format: version @{[$lockfile->version]}\n";
    $data .= "DISTRIBUTIONS\n";

    for my $dist ($lockfile->distributions) {
        $data .= "  @{[$dist->name]}\n";
        $data .= "    pathname: @{[$dist->pathname]}\n";

        $data .= "    provides:\n";
        for my $package (sort keys %{$dist->provides}) {
            $data .= "      $package @{[$dist->provides->{$package}{version} || 'undef' ]}\n";
        }

        $data .= "    requirements:\n";
        for my $module ($dist->required_modules) {
            $data .= "      $module @{[ $dist->requirements_for_module($module) || '0' ]}\n";
        }
    }

    $data;
}

1;
