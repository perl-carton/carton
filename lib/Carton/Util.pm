package Carton::Util;
use strict;
use warnings;

sub load_json {
    my $file = shift;

    open my $fh, "<", $file or die "$file: $!";
    from_json(join '', <$fh>);
}

sub dump_json {
    my($data, $file) = @_;

    open my $fh, ">", $file or die "$file: $!";
    binmode $fh;
    print $fh to_json($data);
}

sub from_json {
    require JSON;
    JSON::decode_json(@_);
}

sub to_json {
    my($data) = @_;
    require JSON;
    JSON->new->utf8->pretty->canonical->encode($data);
}

1;
