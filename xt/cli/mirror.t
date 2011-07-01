use strict;
use Test::More;
use xt::CLI;
use Cwd;

my $cwd = Cwd::cwd();

{
    my $app = cli();

    $app->config->define(section => "cpanm", name => "mirror", value => "$cwd/xt/mirror", origin => __FILE__);
    $app->run("install", "Hash::MultiValue");

    $app->run("list");
    is $app->output, "Hash-MultiValue-0.08\n";
}

done_testing;



