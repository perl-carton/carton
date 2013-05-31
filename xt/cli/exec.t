use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->run("exec", "--system", "--", "perl", "-e", "use Try::Tiny");
    like $app->system_error, qr/Can't locate Try\/Tiny.pm/;

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny';
EOF

    $app->run("install");
    $app->run("exec", "--system", "--", "perl", "-e", 'use Try::Tiny; print "OK\n"');

    like $app->system_output, qr/OK/;

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny';
requires 'Mojolicious';
EOF

    $app->run("install");
    $app->run("exec", "--system", "--", "mojo", "version");

    like $app->system_output, qr/Mojolicious/;
}

{
    my $app = cli();

    my $exec_args = ["exec", "--system", "perl", "-e", "use Try::Tiny"];
    $app->parse_carton_options($exec_args);
    is scalar(@$exec_args), 5;
    is $exec_args->[0], "exec";
    is $exec_args->[1], "--system";
    is $exec_args->[2], "perl";

    $app->run("exec", "--system", "perl", "-e", "use Try::Tiny");
    like $app->system_error, qr/Can't locate Try\/Tiny.pm/;

    $app->dir->touch("cpanfile", <<EOF);
requires 'Try::Tiny';
EOF

    $app->run("install");

    $app->run("exec", "--system", "perl", "-e", 'use Try::Tiny; print "OK\n"');

    like $app->system_output, qr/OK/;

    $app->run("-v", "exec", "perl", "-e", 'print "perl\n"'); # this shows version of carton: "carton -v exec ..."

    like $app->output, qr/carton/;

    $app->run("exec", "--system", "perl", "-v"); # this shows version of perl: "carton exec perl -v"

    like $app->system_output, qr/perl/;

    $app->run("exec", "--system", "perl", "-e", 'print join(",",@INC),"\n"');

    unlike $app->system_output, qr/,lib,/;

    $app->run("exec", "--system", "-Ilib", "perl", "-e", 'print join(",",@INC),"\n"');

    like $app->system_output, qr/,lib,/;
}

done_testing;

