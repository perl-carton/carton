use strict;
use Test::More;

use xt::CLI;

like run("version")->output, qr/carton $Carton::VERSION/;

done_testing;

