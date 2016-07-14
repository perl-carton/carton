use strict;
use Test::More;
use xt::CLI;


subtest 'carton require' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("require", "Try::Tiny");
    $app->run("tree");
    like $app->stdout, qr/Try::Tiny/;
};

subtest 'carton require - without module name' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("require");
    like $app->stderr, qr/module/;
    is $app->exit_code, 255;
};

subtest 'carton require - unknown module' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("require", "CyberspaceHasGotToBeAnAnarchyAPirateConceptInAndOutAndOverMe");
    is $app->exit_code, 255;

    $app->run("tree");
    unlike $app->stdout, qr/CyberspaceHasGotToBeAnAnarchyAPirateConceptInAndOutAndOverMe/;
};

subtest 'carton require - module already in cpanfile' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny';
EOF

    $app->run("require", "Try::Tiny");
    like $app->stdout, qr/already/;
};

subtest 'carton require - core module' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("require", "File::Spec");
    like $app->stdout, qr/core/;
    like $app->dir->child('cpanfile')->slurp, qr/requires 'File::Spec';/;
};

subtest 'carton require - new core module with forced update' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("require", "--update-core", "File::Spec");
    like $app->stdout, qr/core/;
    like $app->dir->child('cpanfile')->slurp, qr/requires 'File::Spec', '[0-9\.]+';/;
};

subtest 'carton require - existing core module with forced update' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'File::Spec';
EOF

    $app->run("require", "--update-core", "File::Spec");
    like $app->stdout, qr/core/;
    like $app->dir->child('cpanfile')->slurp, qr/requires 'File::Spec', '[0-9\.]+';/;
};

subtest 'carton require for develop phase' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("require", "--phase", "develop", "Try::Tiny");
    like $app->stdout, qr/develop/;

    $app->run("tree");
    like $app->stdout, qr/Try::Tiny/;
};

subtest 'carton recommend' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("recommend", "Try::Tiny");
    like $app->dir->child('cpanfile')->slurp, qr/recommends.*Try::Tiny/;
};

subtest 'carton suggest' => sub {
    my $app = cli();
    $app->write_cpanfile();

    $app->run("suggest", "Try::Tiny");
    like $app->dir->child('cpanfile')->slurp, qr/suggests.*Try::Tiny/;
};

done_testing;
