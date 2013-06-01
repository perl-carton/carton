use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->run("exec", "perl", "-e", 1);
    like $app->output, qr/carton\.lock/;
}

{
    my $app = cli();
    $app->dir->touch("cpanfile", '');
    $app->run("install");

    $app->run("exec", "--", "perl", "-e", "use Try::Tiny");
    like $app->system_error, qr/Can't locate Try\/Tiny.pm/;

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");

    $app->run("exec", "--", "perl", "-e", 'use Try::Tiny; print $Try::Tiny::VERSION, "\n"');
    like $app->system_output, qr/0\.11/;

    $app->run("exec", "perl", "-e", 'use Try::Tiny; print $Try::Tiny::VERSION, "\n"');
    like $app->system_output, qr/0\.11/, "No need for -- as well";

 TODO: {
        local $TODO = "Because of PERL5OPT loading order";
        $app->run("exec", "perl", "-MTry::Tiny", "-e", 'print $Try::Tiny::VERSION, "\n"');
        like $app->system_output, qr/0\.11/;
    }

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny';
requires 'Mojolicious', '== 4.01';
EOF

    $app->run("install");
    $app->run("exec", "--", "mojo", "version");

    like $app->system_output, qr/Mojolicious \(4\.01/;
}

done_testing;

