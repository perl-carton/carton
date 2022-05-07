use strict;
use Test::More;
use lib ".";
use xt::CLI;

subtest 'carton outdated shows pinned module' => sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '== 0.09';
EOF

    $app->run("install");
    $app->run("outdated");

    like $app->stdout, qr/Try::Tiny\s+0.09\s+[0-9.]+\s+/;
    is $app->stderr, '';
};

subtest 'carton outdated shows ranged module' => sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '>= 0.09, <= 0.12';
EOF

    $app->run("install");
    $app->run("outdated");

    like $app->stdout, qr/Try::Tiny\s+0.12\s+[0-9.]+\s+/;
    is $app->stderr, '';
};

subtest 'carton outdated wont show unpinned module' => sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny', '0.09';
EOF

    $app->run("install");
    $app->run("outdated");

    is $app->stdout, '';
    is $app->stderr, '';
};

done_testing;
