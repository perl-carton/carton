use strict;
use Test::More;
use xt::CLI;

subtest 'carton check fails when there is no lock' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("check");
    like $app->stderr, qr/find cpanfile\.snapshot/;
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
requires 'Try::Tiny', '0.16';
EOF

    $app->run("check");
    like $app->stdout, qr/not satisfied/;

 TODO: {
        local $TODO = 'exec does not verify lock';
        $app->run("exec", "perl", "use Try::Tiny");
        like $app->stderr, qr/\.snapshot/;
    }

    $app->run("install");

    $app->run("check");
    like $app->stdout, qr/are satisfied/;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.\d\d/;

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

subtest 'detect unused modules' => sub {
    my $app = cli;
    $app->write_cpanfile("requires 'Try::Tiny';");

    $app->run("install");
    $app->write_cpanfile("");


 TODO: {
        local $TODO = "Can't detect superflous modules";
        $app->run("install");
        $app->run("list");
        is $app->stdout, "";

        $app->run("check");
        like $app->stdout, qr/unused/;
    }
};

subtest 'detect downgrade' => sub {
    my $app = cli;
    $app->write_cpanfile("requires 'URI';");
    $app->run("install");

    $app->write_cpanfile("requires 'URI', '== 1.59';");
    $app->run("check");

    like $app->stdout, qr/not satisfied/;
    like $app->stdout, qr/URI has version .* Needs == 1\.59/;
};

done_testing;

