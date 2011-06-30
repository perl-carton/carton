use strict;
use Test::More;
use xt::CLI;
use Cwd;

my $cwd = Cwd::cwd();

{
    my $app = cli();

    $app->dir->touch("Makefile.PL", <<EOF);
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'foo',
  VERSION => '0.1',
  PREREQ_PM => {
    CGI  => 3.50,
    FCGI => 0.72,
  },
);
EOF

    $app->run("install");
    $app->run("uninstall", "CGI");

    like $app->output, qr/Uninstalling CGI/;
    unlike $app->output, qr/Uninstalling FCGI/;

    $app->run("list");
    unlike $app->output, qr/^CGI-/m;
    like $app->output, qr/FCGI-/;

    $app->run("uninstall", "FCGI");
    like $app->output, qr/Uninstalling FCGI/;
}

done_testing;



