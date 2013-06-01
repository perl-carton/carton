use strict;
use Test::More;
use xt::CLI;

plan skip_all => "perl <= 5.14" if $] >= 5.015;

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'JSON';
requires 'CPAN::Meta', '2.12';
EOF

    $app->run("install");
    $app->clean_local;

    TODO: {
        local $TODO = "collect installs";
        $app->run("install", "--deployment");
        unlike $app->system_error, qr/JSON::PP is not in range/;
    }
}

done_testing;

