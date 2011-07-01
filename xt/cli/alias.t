use strict;
use warnings;
use Test::More;
use xt::CLI;

{
    my $app;

    $app = run("foo");
    like $app->output, qr/Could not find command 'foo'/;

    $app->run("config", "alias.foo", "version");

    $app->run("foo");
    like $app->output, qr/carton $Carton::VERSION/;
}

done_testing;

