use strict;
use Test::More;
use xt::CLI;
use Cwd;

my $cwd = Cwd::cwd();

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
on test => sub {
    requires 'Test::NoWarnings';
};
EOF

    $app->run("install");

    $app->run("list");
    like $app->output, qr/Test-NoWarnings/;
}

done_testing;



