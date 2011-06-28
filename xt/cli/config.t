use strict;
use warnings;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->run("config", "foo");
    is $app->output, '';

    $app->run("config", "foo", "bar");
    $app->run("config", "foo");
    is $app->output, "bar\n";

    $app->run("config", "--global", "foo", "baz");
    $app->run("config", "--global", "foo");
    is $app->output, "baz\n";

    $app->run("config", "foo");
    is $app->output, "bar\n";

    $app->run("config", "--unset", "foo");
    $app->run("config", "foo");
    is $app->output, "baz\n", "global config";

    $app->run("config", "--unset", "--global", "foo");
    $app->run("config", "foo");
    is $app->output, "";
}

done_testing;

