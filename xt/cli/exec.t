use strict;
use Test::More;
use lib ".";
use xt::CLI;

subtest 'carton exec without a command', sub {
    my $app = cli();
    $app->write_cpanfile('');
    $app->run("install");
    $app->run("exec");
    like $app->stderr, qr/carton exec needs a command/;
    is $app->exit_code, 255;
};

subtest 'exec without cpanfile', sub {
    my $app = cli();
    $app->run("exec", "perl", "-e", 1);
    like $app->stderr, qr/Can't locate cpanfile/;
    is $app->exit_code, 255;
};

subtest 'exec without a snapshot', sub {
    my $app = cli();
    $app->write_cpanfile();
    $app->run("exec", "perl", "-e", 1);
    like $app->stderr, qr/cpanfile\.snapshot/;
    is $app->exit_code, 255;
};

subtest 'carton exec', sub {
    my $app = cli();
    $app->write_cpanfile('');
    $app->run("install");

 TODO: {
        local $TODO = "exec now does not strip site_perl";
        $app->run("exec", "perl", "-e", "use Try::Tiny");
        like $app->stderr, qr/Can't locate Try\/Tiny.pm/;
    }

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");

    $app->run("exec", "--", "perl", "-e", 'use Try::Tiny; print $Try::Tiny::VERSION, "\n"');
    like $app->stdout, qr/0\.11/;

    $app->run("exec", "perl", "-e", 'use Try::Tiny; print $Try::Tiny::VERSION, "\n"');
    like $app->stdout, qr/0\.11/, "No need for -- as well";

    $app->run("exec", "perl", "-MTry::Tiny", "-e", 'print $Try::Tiny::VERSION, "\n"');
    like $app->stdout, qr/0\.11/;

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny';
requires 'App::Ack', '== 2.02';
EOF

    $app->run("install");
    $app->run("exec", "--", "ack", "--version");

    like $app->stdout, qr/ack 2\.02/;
};

subtest 'carton exec perl -Ilib', sub {
    my $app = cli();
    $app->write_cpanfile('');
    $app->run("install");

    $app->dir->child("lib")->mkpath;
    $app->dir->child("lib/FooBarBaz.pm")->spew("package FooBarBaz; 1");

    $app->run("exec", "perl", "-Ilib", "-e", 'use FooBarBaz; print "foo"');
    like $app->stdout, qr/foo/;
    unlike $app->stderr, qr/exec -Ilib is deprecated/;

    $app->run("exec", "-Ilib", "perl", "-e", 'print "foo"');
    like $app->stdout, qr/foo/;
    like $app->stderr, qr/exec -Ilib is deprecated/;
};

done_testing;

