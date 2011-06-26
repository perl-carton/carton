package Carton::Util;
use strict;
use warnings;

sub parse_json {
    my $file = shift;

    open my $fh, "<", $file or die "$file: $!";

    require JSON;
    JSON::decode_json(join '', <$fh>);
}

1;

