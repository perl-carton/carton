use strict;
use Test::More;
use lib ".";
use xt::CLI;

{
    my $app = cli();
    $app->run("install");
    like $app->stderr, qr/Can't locate cpanfile/;
    is $app->exit_code, 255;
}

done_testing;

