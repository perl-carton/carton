use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->dir->child("cpanfile")->spew(<<EOF);
requires 'perl', '5.8.5';
requires 'Hash::MultiValue';
EOF

    $app->run("install");
    like $app->stdout, qr/Complete/;

    $app->run("list");
    like $app->stdout, qr/Hash-MultiValue-/;
}

done_testing;



