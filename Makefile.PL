use inc::Module::Install;
name 'carton';
version_from 'lib/Carton.pm';
all_from 'bin/carton';
readme_from('bin/carton');

requires 'version', 0.77;
requires 'JSON';
requires 'App::cpanminus', 1.5000;
requires 'Term::ANSIColor';
requires 'Module::Metadata', 1.000003;

install_script 'bin/carton';

build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
WriteAll;
