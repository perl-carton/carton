use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->run("exec", "--system", "--", "perl", "-e", "use Try::Tiny");
    like $app->system_error, qr/Can't locate Try\/Tiny.pm/;

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny';
EOF

    $app->run("install");
    $app->run("exec", "--system", "--", "perl", "-e", 'use Try::Tiny; print "OK\n"');

    like $app->system_output, qr/OK/;

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny';
requires 'Mojolicious';
EOF

    $app->run("install");
    $app->run("exec", "--system", "--", "mojo", "version");

    like $app->system_output, qr/Mojolicious/;
}

done_testing;

