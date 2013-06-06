use strict;
use Test::More;
use xt::CLI;

subtest 'carton check fails when there is no lock' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("check");
    like $app->stderr, qr/find carton\.lock/;
};

subtest 'carton install and check' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");

    $app->run("check");
    like $app->stdout, qr/are satisfied/;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.11/;

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '0.12';
EOF

    $app->run("check");
    like $app->stdout, qr/not satisfied/;

 TODO: {
        local $TODO = 'exec does not verify lock';
        $app->run("exec", "perl", "use Try::Tiny");
        like $app->stderr, qr/lock/;
    }

    $app->run("install");

    $app->run("check");
    like $app->stdout, qr/are satisfied/;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.12/;

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '10.00';
EOF

    $app->run("check");
    like $app->stdout, qr/not satisfied/;

    $app->run("install");
    like $app->stderr, qr/failed/;

    $app->run("check");
    like $app->stdout, qr/not satisfied/;
};

done_testing;

