use strict;
use Test::More;
use xt::CLI;
use Cwd;

my $cwd = Cwd::cwd();

{
    # split string
    my $app = cli();
    $app->dir->touch("cpanfile", <<EOF);
requires 'PSGI';
EOF

    $app->carton->{mirror} = "$cwd/xt/mirror,http://cpan.metacpan.org/";
    $app->run("install");

    $app->run("list");
    like $app->output, qr/^PSGI-/;
}

{
    # ARRAY ref
    my $app = cli();
    $app->dir->touch("cpanfile", <<EOF);
requires 'PSGI';
EOF

    $app->carton->{mirror} = ["$cwd/xt/mirror", "http://cpan.metacpan.org/"];
    $app->run("install");
    $app->run("list");
    like $app->output, qr/^PSGI-/;
}


done_testing;



