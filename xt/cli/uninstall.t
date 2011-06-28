use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->run("install", "Try::Tiny");
    $app->run("list");
    like $app->output, qr/Try-Tiny-/;

    $app->run("uninstall", "Try::Tiny");
    like $app->output, qr/Uninstalling Try-Tiny-/;

    $app->run("list");
    like $app->output, qr/^\s*$/s;
}

done_testing;

