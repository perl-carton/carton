use strict;
use Test::More;
use xt::CLI;
use Cwd;

my $cwd = Cwd::cwd();

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'perl', '5.8.5';
requires 'Hash::MultiValue';
EOF

    $app->run("install");
    like $app->output, qr/Complete/;

    $app->run("list");
    like $app->output, qr/Hash-MultiValue-/;
}

done_testing;



