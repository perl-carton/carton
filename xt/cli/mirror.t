use strict;
use Test::More;
use xt::CLI;

my $cwd = Path::Tiny->cwd;

{
    my $app = cli();

    $app->write_cpanfile(<<EOF);
requires 'Hash::MultiValue';
EOF

    local $ENV{PERL_CARTON_MIRROR} = "$cwd/xt/mirror";
    $app->run("install");

    $app->run("list");
    like $app->stdout, qr/^Hash-MultiValue-0.08/m;
}

{
    # fallback to CPAN
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'PSGI';
EOF

    local $ENV{PERL_CARTON_MIRROR} = "$cwd/xt/mirror";
    $app->run("install");

    $app->run("list");
    like $app->stdout, qr/^PSGI-/m;
}

done_testing;



