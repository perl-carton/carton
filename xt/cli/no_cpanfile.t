use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->run("install");
    like $app->output, qr/Can't locate cpanfile/;
}

done_testing;

