use inc::Module::Install;
name 'carton';
version_from 'lib/Carton.pm';
perl_version '5.008001';
license_from 'lib/Carton.pod';
readme_from('lib/Carton.pod');

configure_requires 'version', 0.77;

requires 'JSON';
requires 'App::cpanminus', 1.4900;
requires 'Term::ANSIColor', 1.12;
requires 'Module::Metadata', 1.000003;
requires 'Try::Tiny';

install_script 'bin/carton';

doc_to_pods();

build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
WriteAll;

sub doc_to_pods {
    # lib/Carton/Doc/*.pod => docs/carton-*.pod => blib/man1/carton-*.1

    my %pods;

    for my $file ("lib/Carton.pod", glob "lib/Carton/Doc/*.pod") {
        my $base = ($file =~ m!lib/(.*?)\.pod!)[0];
           $base =~ s!/!::!g;
        my $name = $base eq 'Carton' ? "carton" : ("carton-" . lc( (split /::/, $base)[-1] ));
        my $doc = "docs/$name.pod";

        if ($Module::Install::AUTHOR) {
            mkdir "docs", 0777;
            copy_pod($file, $doc, $base => $name);
        }

        $pods{$doc} = "blib/man1/$name.1"
    }

    \%pods;

    makemaker_args MAN1PODS => \%pods;
}

sub copy_pod {
    my($src, $dest, $pod_name, $man) = @_;

    warn "Copying $src -> $dest\n";

    open my $in, "<", $src    or die "$src: $!";
    open my $out, ">", $dest  or die "$dest: $!";

    my $match;
    while (<$in>) {
        unless ($match) {
            s/^$pod_name - /$man - /
                and $match++;
        }
        print $out $_;
    }

    unless ($match) {
        die "Couldn't find NAME $pod_name in $src";
    }
}
