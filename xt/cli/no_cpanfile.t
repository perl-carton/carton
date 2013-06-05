use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->run("install");
    like $app->stderr, qr/Can't locate cpanfile/;
}

done_testing;

