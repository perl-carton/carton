package Carton::Config;
use strict;
use warnings;

use parent qw(Config::GitLike);

use File::Basename ();
use File::Path ();

sub load_defaults {
    my $self = shift;

    return if $self->{loaded_defaults};

    $self->data({}) unless $self->is_loaded;

    my @defaults = (
        [ 'environment', 'path' => 'local' ],
        [ 'cpanm', 'path' => 'cpanm' ],
        [ 'cpanm', 'mirror' => 'http://cpan.metacpan.org/' ],
    );

    for my $default (@defaults) {
        my($section, $name, $value) = @$default;
        my $v = $self->get(key => "$section.$name");
        unless (defined $v) {
            $self->define(section => $section, name => $name, value => $value, origin => 'module');
        }
    }

    $self->{loaded_defaults} = 1;
}

sub set {
    my($self, %args) = @_;

    if ($args{filename}) {
        my $dir = File::Basename::dirname($args{filename});
        File::Path::mkpath([ $dir ], 0, 0777);
    }

    $self->SUPER::set(%args);
}

1;

