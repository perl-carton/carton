package Carton::Packer;
use strict;
use App::FatPacker;
use File::pushd ();
use Path::Tiny ();

use Moo;

sub fatpack_carton {
    my($self, $dir) = @_;

    my $temp = Path::Tiny->tempdir;
    my $pushd = File::pushd::pushd $temp;

    my $file = $temp->child('carton.pre.pl');

    $file->spew(<<'EOF');
#!/usr/bin/env perl
use strict;
use 5.008001;
use Carton::CLI;
$Carton::Fatpacked = 1;
exit Carton::CLI->new->run(@ARGV);
EOF

    my $packer = App::FatPacker->new;

    my @modules = split /\r?\n/, $packer->trace(args => [$file], use => ['App::cpanminus']);

    my @packlists = $packer->packlists_containing(\@modules);
    $packer->packlists_to_tree(Path::Tiny->new('fatlib')->absolute, \@packlists);

    my $fatpacked = do {
        local $SIG{__WARN__} = sub {};
        $packer->fatpack_file($file);
    };

    my $executable = $dir->child('carton');
    warn "Bundling $executable\n";

    $dir->mkpath;
    $executable->spew($fatpacked);
    chmod 0755, $executable;
}

1;
