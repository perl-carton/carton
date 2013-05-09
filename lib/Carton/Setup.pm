package Carton::Setup;
use strict;
use Carton;

sub import {
    my $class = shift;
    my %args = @_;

    if (! exists $args{setup}) {
        $args{setup} = 1;
    }

    if (! delete $args{setup}) {
        return;
    }

    setup(%args);
}

sub setup {
    my $params = setup_params(@_);

    # ENV{PATH} should be set
    $ENV{PATH} = $params->{path};

    # lib::core::only is a must, and it must be loaded BEFORE
    # other paths are set
    require lib::core::only;
    lib::core::only->import;

    # @INC, not ENV{PERL5LIB} or ENV{PERL5OPT} should be set
    foreach my $lib (@{ $params->{includes} }) {
        lib->import($lib);
    }
}

sub setup_env {
    my $params = setup_params(@_);

    $ENV{PERL5OPT} = "-Mlib::core::only -Mlib=$params->{includes}";
    $ENV{PATH} = $params->{path};
}

sub setup_params {
    my %args = @_;

    my $carton = Carton->new;
    my $path = $args{path} || $carton->{path};
    my $includes = $args{includes} || [];

    my %params = (
        includes => [ @$includes, "$path/lib/perl5", "." ],
        path     => "$path/bin:$ENV{PATH}",
    );

    return \%params;;
}

1;
__END__

=head1 NAME

Carton::Setup - Setup Environment For Scripts In Carton Capable Apps

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use Carton::Setup; # sets up @INC and $ENV{PATH} 

    use MyApp; # @INC properly contains local/lib/perl5 and stuff

=head1 DESCRIPTION

This modules sets up the proper paths so random scripts in your carton-enable 
application work as expected.

All you need to do is to "use" this module in your script:

    use Carton::Setup

If you want to specify additional paths to be included in @INC, use the
inclues option:

    use Carton::Setup
        includes => [ qw( path/to/lib path/to/another ) ]
    ;

You can disable automatic setup (but if you're doing this, you're either
the author of carton, or you are doing something completely wrong):

    use Carto::Setup setup => 0;

=cut
