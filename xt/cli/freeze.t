use strict;
use Test::More;
use xt::CLI;

use File::Path qw(rmtree);

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");
    $app->run("list");
    like $app->output, qr/Try-Tiny-0\.11/;

    rmtree($app->dir . "/local", 1);

    $app->run("install");
    $app->run("list");
    like $app->output, qr/Try-Tiny-0\.11/;
}

done_testing;

