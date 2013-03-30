package Carton::TreeNode;
use strict;
use warnings;
use version; our $VERSION = version->declare("v0.9.13");

my %cache;

sub cached {
    my($class, $key) = @_;
    return $cache{$key};
}

sub new {
    my($class, $key, $pool) = @_;

    my $meta = delete $pool->{$key} || {};

    my $self = bless [ $key, $meta,  [] ], $class;
    $cache{$key} = $self;

    return $self;
}

sub dump {
    my $self = shift;
    $self->walk_down(sub {
        my($node, $depth) = @_;
        print " " x $depth;
        print $node->key, "\n";
    });
}

sub walk_down {
    my($self, $cb) = @_;
    $self->_walk_down($cb, undef, 0);
}

sub _walk_down {
    my($self, $pre_cb, $post_cb, $depth) = @_;

    my @child = $self->children;
    for my $child ($self->children) {
        local $Carton::Tree::Abort = 0;
        if ($pre_cb) {
            $pre_cb->($child, $depth, $self);
        }

        unless ($Carton::Tree::Abort) {
            $child->_walk_down($pre_cb, $post_cb, $depth + 1);
        }

        if ($post_cb) {
            $post_cb->($child, $depth, $self);
        }
    }
}

sub abort {
    $Carton::Tree::Abort = 1;
}

sub key      { $_[0]->[0] }
sub metadata { $_[0]->[1] }

sub spec {
    my $self = shift;

    my $meta = $self->metadata;
    my $version = $meta->{provides}{$meta->{name}}{version} || $meta->{version};
    $meta->{name} . ($version ? '~' . $version : '');
}

sub children { @{$_[0]->[2]} }

sub add_child {
    my $self = shift;
    push @{$self->[2]}, @_;
}

sub remove_child {
    my($self, $rm) = @_;

    my @new;
    for my $child (@{$self->[2]}) {
        if ($rm->key eq $child->key) {
            undef $child;
        } else {
            push @new, $child;
        }
    }

    $self->[2] = \@new;
}

sub is {
    my($self, $node) = @_;
    $self->key eq $node->key;
}

package Carton::Tree;
our @ISA = qw(Carton::TreeNode);

sub new {
    bless [0, {}, []], shift;
}

sub finalize {
    my($self, $want_root) = @_;

    $want_root ||= {};

    my %subtree;
    my @ancestor;

    my $down = sub {
        my($node, $depth, $parent) = @_;

        if (grep $node->is($_), @ancestor) {
            $parent->remove_child($node);
            return $self->abort;
        }

        $subtree{$node->key} = 1 if $depth > 0;

        push @ancestor, $node;
        return 1;
    };

    my $up = sub { pop @ancestor };
    $self->_walk_down($down, $up, 0);

    # normalize: remove root nodes that are sub-tree of another
    for my $child ($self->children) {
        if ($subtree{$child->key}) {
            $self->remove_child($child);
        }
    }

    # Ugh, but if the build file is there, restore the links to sub-tree as a root elements
    my %curr_root = map { ($_->key => 1) } $self->children;
    for my $key (keys %$want_root) {
        my $node = $self->find_child($key) or next;
        unless ($curr_root{$node->key}) {
            $self->add_child($node);
        }
    }

    %cache = ();
}

sub find_child {
    my($self, $key) = @_;

    my $child;
    $self->walk_down(sub {
        if ($_[0]->key eq $key) {
            $child = $_[0];
            return $self->abort;
        }
    });

    return $child;
}

1;
