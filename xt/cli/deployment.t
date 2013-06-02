use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install", "--deployment");
    like $app->output, qr/deployment requires carton\.lock/;

    $app->run("install");
    $app->clean_local;

    $app->run("install", "--deployment");
    $app->run("list");
    like $app->output, qr/Try-Tiny-0\.11/;

    $app->run("exec", "perl", "-e", "use Try::Tiny 2;");
    like $app->system_error, qr/Try::Tiny.* version 0\.11/;
}

done_testing;

