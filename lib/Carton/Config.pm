package Carton::Config;
use strict;
use warnings;

use Carton::Util;
use Cwd;
use JSON;

sub new {
    my $class = shift;
    bless { global => undef, values => {}, defaults => {} }, $class;
}

sub set_defaults {
    my($self, %values) = @_;
    $self->{defaults} = \%values;
}

sub get {
    my($self, $key) = @_;
    return exists $self->{values}{$key}   ? $self->{values}{$key}
         : exists $self->{defaults}{$key} ? $self->{defaults}{$key}
         : undef;
}

sub set {
    my($self, $key, $value) = @_;
    $self->{values}{$key} = $value;
}

sub remove {
    my($self, $key) = @_;
    delete $self->{values}{$key};
}

sub load {
    my $class = shift;
    my $self = $class->new;

    $self->load_global;
    $self->load_local;

    return $self;
}

sub global {
    my $self = shift;
    $self->{global} = shift if @_;
    $self->{global};
}

sub global_dir {
    "$ENV{HOME}/.carton";
}

sub global_file {
    my $self = shift;
    return $self->global_dir . "/config";
}

sub local_dir {
    my $self = shift;
    Cwd::cwd . "/.carton";
}

sub local_file {
    my $self = shift;
    return $self->local_dir . "/config";
}

sub load_global {
    my $self = shift;
    $self->load_file($self->global_file);
}

sub load_local {
    my $self = shift;
    $self->load_file($self->local_file);
}

sub load_file {
    my($self, $file) = @_;

    my $values = -e $file ? Carton::Util::load_json($file) : {};
    @{$self->{values}}{keys %$values} = values %$values;
}

sub save {
    my $self = shift;
    $self->global ? $self->save_global : $self->save_local;
}

sub save_global {
    my $self = shift;
    $self->save_file($self->global_file, $self->global_dir);
}

sub save_local {
    my $self = shift;
    mkdir Cwd::cwd . "/.carton", 0777;
    $self->save_file($self->local_file, $self->local_dir);
}

sub save_file {
    my($self, $file, $dir) = @_;
    mkdir $dir, 0777 unless -e $dir;
    Carton::Util::dump_json($self->{values}, $file);
}

sub dump {
    my($self, $file) = @_;
    Carton::Util::to_json($self->{values});
}

1;
