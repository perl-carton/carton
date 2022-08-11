use strict;
use Test::More;
use lib ".";
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

subtest 'carton update from mirror' => sub {
    my $app = cli();
    my $cwd = Path::Tiny->cwd;

    local $ENV{PERL_CARTON_CPANFILE} = $app->dir->child('cpanfile.mirror')->absolute;

    $app->write_file('cpanfile.mirror', <<EOF);
mirror '$cwd/xt/mirror';
requires 'Hash::MultiValue';
EOF

    $app->run("install");
    $app->run("update");
    # diag $app->stdout;
    # diag $app->stderr;

    like $app->stdout, qr/^Hash::MultiValue is up to date\. \(0\.08\)/m;

    ok $app->dir->child('cpanfile.mirror.snapshot')->exists;

    # Again, without mirror - will update to latest version
    $app->write_file('cpanfile.mirror', <<EOF);
requires 'Hash::MultiValue';
EOF

    $app->run("update");
    # installed...
    like $app->stdout,
      qr/Successfully installed Hash-MultiValue-[\.0-9]+ \(upgraded from 0\.08\)$/m;

    $app->run("list");
    like $app->stdout, qr/Hash-MultiValue-[\.0-9]+/, 'present';
    unlike $app->stdout, qr/Hash-MultiValue-0\.08/, 'not old';
};


done_testing;

