use strict;
use Test::More;
use xt::CLI;
use Cwd;

{
    my $app = cli();

    $app->dir->touch("cpanfile", <<EOF);
requires 'HTML::Parser';
EOF

    $app->run("install");
    $app->run("tree");

    like $app->output, qr/^HTML-Parser-.*/m;
    like $app->output, qr/^ HTML-Tagset-.*/m;
}

done_testing;



