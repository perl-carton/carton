use strict;
use Test::More;
use xt::CLI;

subtest 'carton update NonExistentModule' => sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.09';
EOF

    $app->run("install");
    $app->run("update", "XYZ");
    like $app->stderr, qr/Could not find module XYZ/;
};

subtest 'carton update upgrades a dist' => sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.09';
EOF

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.09/;

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '>= 0.09, <= 0.12';
EOF

    $app->run("install");
    $app->run("check");
    like $app->stdout, qr/are satisfied/;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.09/;

    $app->run("update", "Try::Tiny");
    like $app->stdout, qr/installed Try-Tiny-0\.12.*upgraded from 0\.09/;

    $app->run("check");
    like $app->stdout, qr/are satisfied/;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.12/;
};

subtest 'downgrade a distribution' => sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '0.16';
EOF
    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.\d\d/;

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.09';
EOF
    $app->run("update");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.09/;

 TODO: {
        local $TODO = 'collecting wrong install info';
        $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '0.09';
EOF
        $app->run("install");
        $app->run("list");
        like $app->stdout, qr/Try-Tiny-0\.09/;
    }
};

done_testing;

