use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");
    $app->run("list");
    like $app->output, qr/Try-Tiny-0\.11/;

    $app->clean_local;

    $app->run("install");
    $app->run("list");
    like $app->output, qr/Try-Tiny-0\.11/;
}

done_testing;

