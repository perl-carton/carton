use strict;
use Test::More;
use xt::CLI;

subtest 'carton install with version range' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'CPAN::Test::Dummy::Perl5::Deps::VersionRange';
EOF

    $app->run("install");
    $app->run("tree");
    like $app->stdout, qr/Try::Tiny/;
    unlike $app->stderr, qr/Could not parse snapshot file/;
};

done_testing;

