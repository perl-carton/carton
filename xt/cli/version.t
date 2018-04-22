use strict;
use Test::More;

use lib ".";
use xt::CLI;

my $app = cli();
$app->run("version");

like $app->stdout, qr/carton $Carton::VERSION/;

done_testing;

