use strict;
use Test::More;
use lib ".";
use xt::CLI;

subtest 'with pinned dist' => sub {
    my $app = cli();
    $app->write_file('cpanfile', <<EOF);
requires 'Try::Tiny', '0.29',
  dist => 'ETHER/Try-Tiny-0.29.tar.gz';
EOF
    $app->run("install");

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.29/;

    $app->run("exec", "perl", "-e", "use Try::Tiny\ 1");
    like $app->stderr, qr/Try::Tiny .* 0\.29/;

    my $content = $app->dir->child('cpanfile.snapshot')->slurp;
    like $content, qr/ETHER\/Try-Tiny-0\.29/;
};

done_testing;
