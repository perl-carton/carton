use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->run("exec", "--system", "--", "perl", "-e", "use Try::Tiny");
    like $app->system_error, qr/Can't locate Try\/Tiny.pm/;

    $app->run("install", "Try::Tiny");
    $app->run("exec", "--system", "--", "perl", "-e", 'use Try::Tiny; print "OK\n"');

    like $app->system_output, qr/OK/;

    $app->run("install", "Mojolicious");
    $app->run("exec", "--system", "--", "mojolicious", "version");

    like $app->system_output, qr/Mojolicious/;
}

done_testing;

