on configure => sub {
    requires 'version', 0.77;
};

requires 'perl', '5.8.5';

requires 'JSON', 2.53;
requires 'Module::Metadata', 1.000003;
requires 'Module::CPANfile', 0.9031;

requires 'Try::Tiny', 0.09;
requires 'parent', 0.223;
requires 'Exception::Class', 1.32;
requires 'Getopt::Long', 2.39;
requires 'Moo', 1.002;
requires 'Path::Tiny', 0.033;

# MYMETA support
requires 'App::cpanminus', 1.6940;
requires 'ExtUtils::MakeMaker', 6.64;
requires 'Module::Build', 0.4004;

requires 'CPAN::Meta', 2.120921;
requires 'CPAN::Meta::Requirements', 2.121;
requires 'Module::CoreList';

requires 'App::FatPacker', 0.009018;
requires 'File::pushd';
requires 'Module::Reader', 0.002;

on develop => sub {
    requires 'Test::More', 0.90;
    requires 'Test::Requires';
    requires 'Capture::Tiny';
};
