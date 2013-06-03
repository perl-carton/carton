use strict;
use Test::More;
use xt::CLI;
use Cwd;

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'Test::TCP';
EOF

    $app->run("install");
    $app->run("tree");

    like $app->output, qr/^Test-TCP-.*\n Test-SharedFork-.*\n  Test-Requires-.*/;
}

done_testing;



