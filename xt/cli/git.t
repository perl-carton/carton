use strict;
use Test::More;
use xt::CLI;

plan skip_all => 'Travis' if $ENV{TRAVIS};

subtest 'carton install with git', sub {
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Hash::MultiValue', '0.15',
  git => 'https://github.com/miyagawa/Hash-MultiValue.git', ref => '0.15';
EOF

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Hash-MultiValue-759bf1b/;

    $app->clean_local;
    $app->run("install", "--deployment");
    $app->run("list");
    like $app->stdout, qr/Hash-MultiValue-759bf1b/;
};

done_testing;

