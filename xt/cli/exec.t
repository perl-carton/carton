use strict;
use Test::More;
use xt::CLI;

use Test::Requires qw(Capture::Tiny);
use Capture::Tiny qw(capture_merged);

{
    my $app = cli();

    ok 1;

    my $out = capture_merged {
        $app->run("exec", "--system", "--", "perl", "-e", "use Try::Tiny");
    };

    like $out, qr/Can't locate Try\/Tiny.pm/;

    $app->run("install", "Try::Tiny");
    $out = capture_merged {
        $app->run("exec", "--system", "--", "perl", "-e", 'use Try::Tiny; print "OK\n"');
    };

    like $out, qr/OK/;

    $app->run("install", "Mojolicious");
    $out = capture_merged {
        $app->run("exec", "--system", "--", "mojolicious", "version");
    };

    like $out, qr/Mojolicious/;
}

done_testing;

