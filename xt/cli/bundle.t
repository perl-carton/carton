use strict;
use Test::More;
use lib ".";
use xt::CLI;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.12';
EOF

    $app->run("install");
    $app->run("bundle");

    ok -f ($app->dir . "/vendor/cache/authors/id/D/DO/DOY/Try-Tiny-0.12.tar.gz");
}

done_testing;

