use strict;
use Test::More;
use xt::CLI;

plan skip_all => "perl <= 5.14" if $] >= 5.015;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'JSON';
requires 'CPAN::Meta', '2.12';
EOF

    $app->run("install");
    $app->clean_local;

    $app->run("install", "--deployment");
    unlike $app->stderr, qr/JSON::PP is not in range/;
}

done_testing;

