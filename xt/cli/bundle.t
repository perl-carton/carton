use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny', '== 0.12';
EOF

    $app->run("install");
    $app->run("bundle");

    ok -f ($app->dir . "/local/cache/authors/id/D/DO/DOY/Try-Tiny-0.12.tar.gz");
}

done_testing;

