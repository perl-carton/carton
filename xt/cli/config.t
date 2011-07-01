use strict;
use warnings;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->run("config", "foo");
    like $app->output, qr/key does not contain a section: foo/;

    $app->run("config", "foo.bar");
    is $app->output, '';

    $app->run("config", "foo.bar", "baz");
    $app->run("config", "foo.bar");
    is $app->output, "baz\n";

    $app->run("config", "--global", "foo.bar", "quux");
    $app->run("config", "--global", "foo.bar");
    is $app->output, "quux\n";

    $app->run("config", "foo.bar");
    is $app->output, "baz\n";

    $app->run("config", "--unset", "foo.bar");
    $app->run("config", "foo.bar");
    is $app->output, "quux\n", "global config";

    $app->run("config", "--unset", "--global", "foo.bar");
    $app->run("config", "foo.bar");
    is $app->output, "";
}

done_testing;

