package Carton::Setup;
use strict;
use Carton;

sub import {
    my $class = shift;
    my %args = @_;

    if (! exists $args{setup}) {
        # If unspecified, run automatic setup
        $args{setup} = 1;
    }

    $class->setup(%args);
}

sub setup {
    my $class = shift;
    my %args = @_;

    if (! $args{setup}) {
        return;
    }
    my $params = $class->setup_params(%args);

    # ENV{PATH} should be set
    $ENV{PATH} = $params->{path};

    # lib::core::only is a must, and it must be loaded BEFORE
    # other paths are set
    require lib::core::only;
    lib::core::only->import;

    # @INC, not ENV{PERL5LIB} or ENV{PERL5OPT} should be set
    my $includes = $params->{includes};
    lib->import(@$includes);
}

sub setup_env {
    my $params = setup_params(@_);

    my $libs = join ",", @{$params->{includes} || []};
    $ENV{PERL5OPT} = "-Mlib::core::only -Mlib=$libs";
    $ENV{PATH} = $params->{path};
}

sub setup_params {
    my $class = shift;
    my %args = @_;

    my $carton = Carton->new;
    my $path = $args{path} || $carton->{path};
    my $includes = $args{includes} || [];

    my %params = (
        includes => [ @$includes, "$path/lib/perl5", "." ],
        path     => "$path/bin:$ENV{PATH}",
    );

    return \%params;
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

    use Carton::Setup;

If you want to specify additional paths to be included in @INC, use the
inclues option:

    use Carton::Setup
        includes => [ qw( path/to/lib path/to/another ) ]
    ;

You can disable automatic setup (but if you're doing this, you're either
the author of carton, or you are doing something completely wrong):

    use Carto::Setup setup => 0;

=head1 API

Please note that regular Carton users DO NOT, and SHOULD NOT need to use 
this API. They are described here for clarification, but they are meant to
be used internally in Carton. These are subject to change.

=head2 $class->setup(%args)

Sets up I<the current process> so module include paths and executable paths are
correctly aligned.

If given the argument C<setup>, it controls if the actual setup should be
executed or not. This is used for Carton-internal code to load Carton::Setup
but to skip automatic setup:

    use Carton::Setup setup => 0;

The rest of arguments are internally sent to C<setup_params()>. Please see C<setup_params()> for details.

=head2 $class->setup_env(%args);

Sets up I<environment variables> so processes spawned from Carton can inherit
the necessary settings.

Note that this I<overwrites> portions of %ENV, so if you want to localize
its effects, you would need to localize %ENV before calling this function:

    local %ENV;
    $class->setup_env(%args);

Arguments are internally sent to C<setup_params()>. Please see C<setup_params()> for details.

=head2 $class->setup_params(%args)

Creates a hashref with information to setup the environment, based on C<%args>.

Arguments may be:

=over 4

=item path

Specifies the location where Carton files are installed. By default this is
"local"

=item includes

Specifies I<extra> directories to look modules for. Note that you do not need
to specify the location inside C<path> above (because it's automatically 
setup)

=back

=head1 CAVEATS

If you're using Carton::Setup in your scripts, you SHOULD specify Carton
itself in your cpanfile, because although this works:

    ./yourscript.pl

But the moment you use 'carton exec', your @INC path will be setup to only
look at application specific directories, so this will fail to load Carton::Setup:

    carton exec -- ./youscript.pl

To avoid this, make sure to specify Carton in your cpanfile:

    requires 'Carton';

=cut
