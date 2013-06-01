use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->run("help");
    like $app->system_output, qr/Carton - Perl module/;

    $app->run("-h");
    like $app->system_output, qr/Carton - Perl module/;

    $app->run("help", "install");
    like $app->system_output, qr/Install the dependencies/;

    $app->run("install", "-h");
    like $app->system_output, qr/Install the dependencies/;

    $app->run("help", "foobarbaz");
    is $app->system_output, '';
    like $app->system_error, qr/No documentation found/;
}

done_testing;

