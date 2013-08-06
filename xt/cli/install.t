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

subtest 'meta info for ancient modules' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'Algorithm::Diff';
EOF

    $app->run("install");
    $app->run("list");

    like $app->stdout, qr/Algorithm-Diff/;
};

subtest 'meta info for modules with version->declare' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'CPAN::Test::Dummy::Perl5::VersionDeclare', 'v0.0.1';
EOF

    $app->run("install");
    $app->run("check");

    like $app->stdout, qr/are satisfied/;
    unlike $app->stderr, qr/is not installed/;
};

subtest 'meta info for modules with qv()' => sub {
    my $app = cli();
    $app->write_cpanfile(<<EOF);
requires 'CPAN::Test::Dummy::Perl5::VersionQV', 'v0.1.0';
EOF

    $app->run("install");
    $app->run("check");

    like $app->stdout, qr/are satisfied/;
    unlike $app->stderr, qr/is not installed/;
};

done_testing;

