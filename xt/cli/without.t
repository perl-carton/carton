use strict;
use Test::More;
use xt::CLI;

subtest 'carton install and check' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Try::Tiny';

on 'develop' => sub {
  requires 'Hash::MultiValue', '== 0.14';
};
EOF

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-/;
    like $app->stdout, qr/Hash-MultiValue-0\.14/;

    $app->run("exec", "perl", "-e", "use Hash::MultiValue\ 1");
    like $app->stderr, qr/Hash::MultiValue .* version 0.14/;

    $app->clean_local;

    $app->run("install", "--without", "develop");
    $app->run("list");
    like $app->stdout, qr/Try-Tiny-/;

 TODO: {
        local $TODO = "--without is not remembered for list";
        unlike $app->stdout, qr/Hash-MultiValue-/;
    }

    $app->run("exec", "perl", "-e", "use Hash::MultiValue\ 1");
    unlike $app->stderr, qr/Hash::MultiValue .* version 0.14/;
};

done_testing;

