use strict;
use Test::More;
use xt::CLI;
use Cwd;

my $cwd = Cwd::cwd();

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'Hash::MultiValue';
EOF

    $app->carton->{mirror} = "$cwd/xt/mirror";
    $app->run("install");

    $app->run("list");
    is $app->output, "Hash-MultiValue-0.08\n";
}

done_testing;



