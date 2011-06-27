use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    $app->dir->touch("Makefile.PL", <<EOF);
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => "foo",
  VERSION => 1,
  PREREQ_PM => {
    "Try::Tiny" => 0,
  },
);
EOF

    $app->run("check");
    like $app->output, qr/Following dependencies are not satisfied.*Try::Tiny/s;
    unlike $app->output, qr/found in local but/;

    $app->run("install");

    $app->run("check");
    like $app->output, qr/matches/;

    $app->run("list");
    like $app->output, qr/Try-Tiny-/;
}


done_testing;

