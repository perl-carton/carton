use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Data::Dumper' => '== 2.139';
requires 'Test::Differences' => '== 0.61';
EOF

    $app->run("install");
    $app->run("list");

    like $app->stdout, qr/Data-Dumper-2\.139/;
    like $app->stdout, qr/Test-Differences-0\.61/;

    $app->run("check");
    like $app->stdout, qr/are satisfied/;
}

done_testing;

