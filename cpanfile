requires 'perl', '5.8.5';

configure_requires 'version', 0.77;

requires 'JSON', 2.53;
requires 'Module::Metadata', 1.000003;
requires 'Try::Tiny', 0.09;
requires 'parent', 0.223;
requires 'local::lib', 1.008;
requires 'Exception::Class', 1.32;
requires 'Getopt::Long', 2.39;
requires 'Moo', '1.002';

# MYMETA support
requires 'App::cpanminus', 1.6915;
requires 'ExtUtils::MakeMaker', 6.59;
requires 'Module::Build', 0.38;
requires 'CPAN::Meta', 2.120921;

on develop => sub {
    requires 'Test::Requires';
    requires 'Directory::Scratch';
    requires 'Capture::Tiny';
    requires 'File::pushd';
};
