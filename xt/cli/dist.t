use strict;
use Test::More;
use xt::CLI;

subtest 'carton install with dist', sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Hash::MultiValue', 0,
  dist => 'MIYAGAWA/Hash-MultiValue-0.13.tar.gz';
EOF

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Hash-MultiValue-0\.13/;

    $app->clean_local;
    $app->run("install", "--deployment");
    $app->run("list");
    like $app->stdout, qr/Hash-MultiValue-0\.13/;
};

done_testing;

