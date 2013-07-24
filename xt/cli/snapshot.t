use strict;
use Test::More;
use xt::CLI;

subtest 'snapshot file has canonical representation' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.11';
requires 'Getopt::Long', '2.41';
EOF

    $app->run("install");

    my $content = $app->dir->child('cpanfile.snapshot')->slurp;
    for (1..3) {
        $app->dir->child('cpanfile.snapshot')->remove;
        $app->run("install");
        is $content, $app->dir->child('cpanfile.snapshot')->slurp;
    }
};

done_testing;

