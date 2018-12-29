use strict;
use Test::More;
use lib ".";
use xt::CLI;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
on test => sub {
    requires 'Test::NoWarnings';
    recommends 'Test::Pretty';
};
on develop => sub {
    requires 'Path::Tiny';
};
EOF

    $app->run("install");

    $app->run("list");
    like $app->stdout, qr/Test-NoWarnings/;
    like $app->stdout, qr/Path-Tiny/;
    unlike $app->stdout, qr/Test-Pretty/;
}

done_testing;



