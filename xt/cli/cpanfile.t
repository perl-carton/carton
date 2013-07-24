use strict;
use Test::More;
use xt::CLI;

subtest 'carton install --cpanfile' => sub {
    my $app = cli();
    $app->write_file('cpanfile.foo', <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF
    $app->run("install", "--cpanfile", "cpanfile.foo");
    $app->run("check", "--cpanfile", "cpanfile.foo");

    ok !$app->dir->child('cpanfile.snapshot')->exists;
    ok $app->dir->child('cpanfile.foo.snapshot')->exists;

    like $app->stdout, qr/are satisfied/;

    local $ENV{PERL_CARTON_CPANFILE} = $app->dir->child('cpanfile.foo')->absolute;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.11/;

    $app->run("exec", "perl", "-e", "use Try::Tiny\ 1");
    like $app->stderr, qr/Try::Tiny .* 0\.11/;
};

subtest 'PERL_CARTON_CPANFILE' => sub {
    my $app = cli();

    local $ENV{PERL_CARTON_CPANFILE} = $app->dir->child('cpanfile.foo')->absolute;

    $app->write_file('cpanfile.foo', <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");
    $app->run("list");

    like $app->stdout, qr/Try-Tiny-0\.11/;
    ok $app->dir->child('cpanfile.foo.snapshot')->exists;
};

done_testing;

