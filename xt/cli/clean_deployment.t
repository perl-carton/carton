use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();
    $app->write_cpanfile(<<'EOF');
requires 'Type::Tiny', '== 1.000005';
EOF

    $app->write_file( 'cpanfile.snapshot' => my $snapshot = <<'EOF' );
# carton snapshot format: version 1.0
DISTRIBUTIONS
  Exporter-Tiny-0.040
    pathname: T/TO/TOBYINK/Exporter-Tiny-0.040.tar.gz
    provides:
      Exporter::Shiny 0.040
      Exporter::Tiny 0.040
    requirements:
      ExtUtils::MakeMaker 6.17
      perl 5.006001
  Type-Tiny-1.000005
    pathname: T/TO/TOBYINK/Type-Tiny-1.000005.tar.gz
    provides:
      Devel::TypeTiny::Perl56Compat 1.000005
      Devel::TypeTiny::Perl58Compat 1.000005
      Error::TypeTiny 1.000005
      Error::TypeTiny::Assertion 1.000005
      Error::TypeTiny::Compilation 1.000005
      Error::TypeTiny::WrongNumberOfParameters 1.000005
      Eval::TypeTiny 1.000005
      Reply::Plugin::TypeTiny 1.000005
      Test::TypeTiny 1.000005
      Type::Coercion 1.000005
      Type::Coercion::FromMoose 1.000005
      Type::Coercion::Union 1.000005
      Type::Library 1.000005
      Type::Params 1.000005
      Type::Parser 1.000005
      Type::Registry 1.000005
      Type::Tiny 1.000005
      Type::Tiny::Class 1.000005
      Type::Tiny::Duck 1.000005
      Type::Tiny::Enum 1.000005
      Type::Tiny::Intersection 1.000005
      Type::Tiny::Role 1.000005
      Type::Tiny::Union 1.000005
      Type::Utils 1.000005
      Types::Common::Numeric 1.000005
      Types::Common::String 1.000005
      Types::Standard 1.000005
      Types::Standard::ArrayRef 1.000005
      Types::Standard::Dict 1.000005
      Types::Standard::HashRef 1.000005
      Types::Standard::Map 1.000005
      Types::Standard::ScalarRef 1.000005
      Types::Standard::Tuple 1.000005
      Types::TypeTiny 1.000005
    requirements:
      Exporter::Tiny 0.026
      ExtUtils::MakeMaker 6.17
      perl 5.006001
EOF

    $app->run(qw/install --clean-deployment/);

    like $app->stdout, qr/
        \QSuccessfully installed Exporter-Tiny-0.040\E\n
        \QSuccessfully installed Type-Tiny-1.000005\E\n
    /x, 'First deployment installs both';

    $app->run(qw/install --clean-deployment/);

    unlike $app->stdout, qr/Successfully installed/,
        'Second install with an unchanged snapshot is a no-op';

    $snapshot =~ s/0.040/0.042/g;   # Upgrade Exporter::Tiny

    $app->write_file( 'cpanfile.snapshot' => $snapshot );

    $app->run(qw/install --clean-deployment/);

    like $app->stdout, qr(
        \QCan't find Exporter-Tiny-0.042 on disk, removing @{[$app->dir]}/local\E\n
        \QSuccessfully installed Exporter-Tiny-0.042\E\n
        \QSuccessfully installed Type-Tiny-1.000005\E\n
        \Q2 distributions installed\E\n
    )x, 'Third install with an altered snapshot reinstalls all the dists';

    $app->write_cpanfile(<<'EOF');
requires 'Exporter::Tiny', '== 0.042';
EOF

    $app->write_file( 'cpanfile.snapshot' => <<'EOF' );
# carton snapshot format: version 1.0
DISTRIBUTIONS
  Exporter-Tiny-0.042
    pathname: T/TO/TOBYINK/Exporter-Tiny-0.042.tar.gz
    provides:
      Exporter::Shiny 0.042
      Exporter::Tiny 0.042
    requirements:
      ExtUtils::MakeMaker 6.17
      perl 5.006001
EOF

    $app->run(qw/install --clean-deployment/);

    like $app->stdout, qr(
        \QOrphaned distribution Type-Tiny-1.000005 on disk, removing @{[$app->dir]}/local\E\n
        \QSuccessfully installed Exporter-Tiny-0.042\E\n
        \Q1 distribution installed\E\n
    )x, 'Fourth install with reduced snapshot reinstalls all the dists';
}

done_testing;
