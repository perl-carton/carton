use strict;
use Test::More;
use xt::CLI;

subtest 'carton exec without a command', sub {
    my $app = cli();
    $app->write_cpanfile('');
    $app->run("install");
    $app->run("exec");
    like $app->stderr, qr/carton exec needs a command/;
    is $app->exit_code, 255;
};

subtest 'exec without a lock', sub {
    my $app = cli();
    $app->run("exec", "perl", "-e", 1);
    like $app->stderr, qr/carton\.lock/;
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
requires 'Mojolicious', '== 4.01';
EOF

    $app->run("install");
    $app->run("exec", "--", "mojo", "version");

    like $app->stdout, qr/Mojolicious \(4\.01/;
};

done_testing;

