use strict;
use Test::More;
use xt::CLI;

plan skip_all => "check is unimplemented";

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny';
EOF

    $app->run("check");
    like $app->output, qr/Following dependencies are not satisfied.*Try::Tiny/s;
    unlike $app->output, qr/found in local but/;

    $app->run("install");

    $app->run("check");
    like $app->output, qr/matches/;

    $app->run("list");
    like $app->output, qr/Try-Tiny-/;
}


done_testing;

