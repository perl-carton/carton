use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->dir->child("cpanfile")->spew(<<EOF);
requires 'Try::Tiny', '== 0.09';
EOF

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.09/;

    $app->dir->child("cpanfile")->spew(<<EOF);
requires 'Try::Tiny', '>= 0.09, <= 0.12';
EOF

    $app->run("install");
    $app->run("check");
    like $app->stdout, qr/are satisfied/;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.09/;

    $app->run("update", "XYZ");
    like $app->stderr, qr/Could not find module XYZ/;

    $app->run("update", "Try::Tiny");
    like $app->stderr, qr/installed Try-Tiny-0\.12.*upgraded from 0\.09/;

    $app->run("check");
    like $app->stdout, qr/are satisfied/;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.12/;
}

done_testing;

