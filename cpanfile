on configure => sub {
    requires 'version', 0.77;
};

requires 'perl', '5.8.5';

requires 'JSON', 2.53;
requires 'Module::Metadata', 1.000003;
requires 'Module::CPANfile', 0.9031;

requires 'Try::Tiny', 0.09;
requires 'parent', 0.223;
requires 'Getopt::Long', 2.39;
requires 'Class::Tiny', 1.001;
requires 'Path::Tiny', 0.033;

requires 'App::cpanminus', 1.7030;

requires 'CPAN::Meta', 2.120921;
requires 'CPAN::Meta::Requirements', 2.121;
requires 'Module::CoreList';

# for fatpack
requires 'Module::Reader', 0.002;
recommends 'File::pushd';
recommends 'App::FatPacker', 0.009018;

on develop => sub {
    requires 'Test::More', 0.90;
    requires 'Test::Requires';
    requires 'Capture::Tiny';
};
