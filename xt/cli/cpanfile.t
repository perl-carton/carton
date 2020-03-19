use strict;
use Test::More;
use lib ".";
use xt::CLI;

subtest 'builder mirrors' => sub {
    require Carton::Builder;
    my $builder = Carton::Builder->new(mirror => Carton::Mirror->new('/tmp'));
    my $mirrors = [ $builder->effective_mirrors ];
    is @$mirrors, 3, 'three mirrors';
    is_deeply $mirrors->[0], {url => '/tmp'}, 'custom mirror';
};


subtest 'carton install --cpanfile' => sub {
    my $app = cli();
    $app->write_file('cpanfile.foo', <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF
    $app->run("install", "--cpanfile", "cpanfile.foo");
    $app->run("check", "--cpanfile", "cpanfile.foo");

    ok !$app->dir->child('cpanfile.snapshot')->exists;
    ok $app->dir->child('cpanfile.foo.snapshot')->exists;

    like $app->stdout, qr/are satisfied/;

    local $ENV{PERL_CARTON_CPANFILE} = $app->dir->child('cpanfile.foo')->absolute;

    $app->run("list");
    like $app->stdout, qr/Try-Tiny-0\.11/;

    $app->run("exec", "perl", "-e", "use Try::Tiny\ 1");
    like $app->stderr, qr/Try::Tiny .* 0\.11/;
};

subtest 'PERL_CARTON_CPANFILE' => sub {
    my $app = cli();

    local $ENV{PERL_CARTON_CPANFILE} = $app->dir->child('cpanfile.foo')->absolute;

    $app->write_file('cpanfile.foo', <<EOF);
requires 'Try::Tiny', '== 0.11';
EOF

    $app->run("install");
    $app->run("list");

    like $app->stdout, qr/Try-Tiny-0\.11/;
    ok $app->dir->child('cpanfile.foo.snapshot')->exists;
};

subtest 'mirrors' => sub {
    my $app = cli();
    my $cwd = Path::Tiny->cwd;

    local $ENV{PERL_CARTON_CPANFILE} = $app->dir->child('cpanfile.mirror')->absolute;

    $app->write_file('cpanfile.mirror', <<EOF);
mirror '$cwd/xt/mirror';
requires 'Hash::MultiValue';
EOF

    $app->run("install");
    # diag $app->stdout;
    # diag $app->stderr;

    $app->run("list");
    like $app->stdout, qr/^Hash-MultiValue-0\.08/m;

    ok $app->dir->child('cpanfile.mirror.snapshot')->exists;
};

subtest 'mirror / dist syntax for requires' => sub {
    my $app = cli();
    my $cwd = Path::Tiny->cwd;

    local $ENV{PERL_CARTON_CPANFILE} = $app->dir->child('cpanfile.mirror')->absolute;

    $app->write_file('cpanfile.mirror', <<EOF);
requires 'Hash::MultiValue',
    dist => 'MIYAGAWA/Hash-MultiValue-0.08.tar.gz',
    mirror => 'file://$cwd/xt/mirror';
EOF

    $app->run("install");
    $app->run("list");
    like $app->stdout, qr/^Hash-MultiValue-0\.08/m;

    ok $app->dir->child('cpanfile.mirror.snapshot')->exists;
};


done_testing;

