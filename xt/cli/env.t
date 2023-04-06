use strict;
use Test::More;
use xt::CLI;
use Capture::Tiny qw( capture );

subtest 'carton env', sub {

    my $app = cli();
    $app->write_cpanfile( '' );
    $app->run( "install" );

    my $stdout;

    # use the exec command to get the expected values of the
    # environment variables.  Note that $^X is used here instead
    # of "perl", as "perl" may be a proxy (e.g. plenv) and may
    # change the environment in such a way that it's difficult
    # to use it as a fiducial value
    my %exp = map {
        $app->run( "exec", $^X, "-le", "print \$ENV{$_}" );
        chomp( my $stdout = $app->stdout );
        ( $_ => quotemeta $stdout );
    } qw[ PATH PERL5LIB ];

    $app->run( "env" );
    like( $app->stdout, qr/export PERL5LIB='$exp{PERL5LIB}';/, "PERL5LIB" );
    like( $app->stdout, qr/export PATH='$exp{PATH}';/,         "PATH" );
};

done_testing;
