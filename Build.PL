
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601",
    "version" => "0.77"
  },
  "dist_abstract" => "Perl module dependency manager (aka Bundler for Perl)",
  "dist_author" => [
    "Tatsuhiko Miyagawa <miyagawa\@bulknews.net>"
  ],
  "dist_name" => "carton",
  "dist_version" => "v0.9.15",
  "license" => "perl",
  "module_name" => "carton",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::cpanminus" => "1.6",
    "CPAN::Meta" => "2.120921",
    "CPAN::Meta::Requirements" => "2.121",
    "Capture::Tiny" => 0,
    "Exception::Class" => "1.32",
    "ExtUtils::MakeMaker" => "6.59",
    "Getopt::Long" => "2.36",
    "IO::Compress::Gzip" => 0,
    "JSON" => "2.53",
    "Module::Build" => "0.38",
    "Module::CPANfile" => "0.9004",
    "Module::Metadata" => "1.000003",
    "Term::ANSIColor" => "1.12",
    "Try::Tiny" => "0.09",
    "local::lib" => "1.008",
    "parent" => "0.223",
    "perl" => "v5.8.5"
  },
  "script_files" => [
    "script/carton"
  ],
  "test_requires" => {}
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
