use strict;
use Test::More;
use lib ".";
use xt::CLI;

subtest 'carton exec in subdir', sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny';
EOF
    $app->run('install');

    $app->dir->child('x')->mkpath;

    $app->run_in_dir('x' => 'list');
    like $app->stdout, qr/Try-Tiny/;

    $app->run_in_dir('x' => 'check');
    like $app->stdout, qr/are satisfied/;

    $app->run_in_dir('x' => 'install');
    like $app->stdout, qr/Complete/;
    unlike $app->stderr, qr/failed/;
};

done_testing;
