use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->run("exec", "perl", "-e", 1);
    like $app->stderr, qr/carton\.lock/;
    is $app->exit_code, 255;
}

{
    my $app = cli();
    $app->dir->child("cpanfile")->spew('');
    $app->run("install");

 TODO: {
        local $TODO = "exec now does not strip site_perl";
        $app->run("exec", "perl", "-e", "use Try::Tiny");
        like $app->stderr, qr/Can't locate Try\/Tiny.pm/;
    }

    $app->dir->child("cpanfile")->spew(<<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");

    $app->run("exec", "--", "perl", "-e", 'use Try::Tiny; print $Try::Tiny::VERSION, "\n"');
    like $app->stdout, qr/0\.11/;

    $app->run("exec", "perl", "-e", 'use Try::Tiny; print $Try::Tiny::VERSION, "\n"');
    like $app->stdout, qr/0\.11/, "No need for -- as well";

    $app->run("exec", "perl", "-MTry::Tiny", "-e", 'print $Try::Tiny::VERSION, "\n"');
    like $app->stdout, qr/0\.11/;

    $app->dir->child("cpanfile")->spew(<<EOF);
requires 'Try::Tiny';
requires 'Mojolicious', '== 4.01';
EOF

    $app->run("install");
    $app->run("exec", "--", "mojo", "version");

    like $app->stdout, qr/Mojolicious \(4\.01/;
}

done_testing;

