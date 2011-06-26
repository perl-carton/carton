use inc::Module::Install;
name 'carton';
version_from 'lib/Carton.pm';
perl_version '5.008001';
license_from 'lib/Carton/Doc/Carton.pod';
readme_from('lib/Carton/Doc/Carton.pod');

requires 'version', 0.77;
requires 'JSON';
requires 'App::cpanminus', 1.5000;
requires 'Term::ANSIColor';
requires 'Module::Metadata', 1.000003;
requires 'Try::Tiny';

install_script 'bin/carton';

makemaker_args MAN1PODS => man1pods();

build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
WriteAll;

sub man1pods {
    my %pods;

    for my $file (glob "lib/Carton/Doc/*.pod") {
        my $name = ($file =~ m!Doc/(.*?)\.pod!)[0];
        $name = $name eq 'Carton' ? "carton" : ("carton-" . lc($name));
        $pods{$file} = "blib/man1/$name.1"
    }

    \%pods;
}
