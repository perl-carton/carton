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

doc_to_pods();

build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
WriteAll;

sub doc_to_pods {
    # lib/Carton/Doc/*.pod => doc/carton-*.pod => blib/man1/carton-*.1

    my %pods;

    for my $file (glob "lib/Carton/Doc/*.pod") {
        my $base = ($file =~ m!Doc/(.*?)\.pod!)[0];
        my $name = $base eq 'Carton' ? "carton" : ("carton-" . lc($base));
        my $doc = "doc/$name.pod";

        if ($Module::Install::AUTHOR) {
            mkdir "doc", 0777;
            copy_pod($file, $doc, "Carton::Doc::$base" => $name);
        }

        $pods{$doc} = "blib/man1/$name.1"
    }

    \%pods;

    makemaker_args MAN1PODS => \%pods;
}

sub copy_pod {
    my($src, $dest, $pod_name, $man) = @_;

    warn "Copying $src -> $dest\n";

    open my $in, "<", $src   or die $!;
    open my $out, ">", $dest or die $!;

    my $match;
    while (<$in>) {
        s/^$pod_name - /$man - / and $match++;
        print $out $_;
    }

    unless ($match) {
        die "Could nto find NAME $pod_name in $src";
    }
}
