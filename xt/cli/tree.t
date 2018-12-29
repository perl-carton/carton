use strict;
use Test::More;
use lib ".";
use xt::CLI;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'HTML::Parser';
EOF

    $app->run("install");
    $app->run("tree");

    is $app->exit_code, 0;
    like $app->stdout, qr/^HTML::Parser \(HTML-Parser-/m;
    like $app->stdout, qr/^ HTML::Tagset \(HTML-Tagset-/m;
}

done_testing;



