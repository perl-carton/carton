use strict;
use Test::More;
use lib ".";
use xt::CLI;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'perl', '5.8.5';
requires 'Hash::MultiValue';
EOF

    $app->run("install");
    like $app->stdout, qr/Complete/;

    $app->run("list");
    like $app->stdout, qr/Hash-MultiValue-/;
}

done_testing;



