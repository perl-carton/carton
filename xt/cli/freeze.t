use strict;
use Test::More;
use lib ".";
use xt::CLI;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.11/;

    $app->clean_local;

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.11/;
}

done_testing;

