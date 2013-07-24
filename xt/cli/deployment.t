use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install", "--deployment");
    like $app->stderr, qr/deployment requires cpanfile\.snapshot/;

    $app->run("install");
    $app->clean_local;

    $app->run("install", "--deployment");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.11/;

    $app->run("exec", "perl", "-e", "use Try::Tiny 2;");
    like $app->stderr, qr/Try::Tiny.* version 0\.11/;
}

done_testing;

