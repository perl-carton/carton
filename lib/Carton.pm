package Carton;

use strict;
use warnings;
use 5.008_001;
use version; our $VERSION = qv('v0.1_0');

use Carton::Util;

sub new {
    my $class = shift;
    bless {
        cpanm => $ENV{PERL_CARTON_CPANM} || 'cpanm',
    }, $class;
}

sub configure {
    my($self, %args) = @_;
    %{$self} = (%$self, %args);
}

sub lock { $_[0]->{lock} }

sub install_from_build_file {
    my($self, $file) = @_;

    my @modules;
    if ($self->lock) {
        my $tree = $self->build_tree($self->lock->{modules});
        push @modules, map $_->spec, $tree->children;
    }

    push @modules, $self->show_deps();
    $self->install_conservative(\@modules, 1)
        or die "Installing modules failed\n";
}

sub show_deps {
    my $self = shift;

    my @deps = $self->run_cpanm_output("--showdeps", ".");
    for my $line (@deps) {
        chomp $line;
    }

    return @deps;
}

sub install_modules {
    my($self, $modules) = @_;
    $self->install_conservative($modules, 1)
        or die "Installing modules failed\n";
}

sub install_from_lock {
    my($self) = @_;

    my $tree = $self->build_tree($self->lock->{modules});
    my @root = map $_->spec, $tree->children;

    $self->install_conservative(\@root, 0)
        or die "Installing modules failed\n";
}

sub dedupe_modules {
    my($self, $modules) = @_;

    my %seen;
    my @result;
    for my $spec (reverse @$modules) {
        my($mod, $ver) = split /~/, $spec;
        next if $seen{$mod}++;
        push @result, $spec;
    }

    return [ reverse @result ];
}

sub install_conservative {
    my($self, $modules, $cascade) = @_;

    $modules = $self->dedupe_modules($modules);

    my $index = $self->build_index($self->lock->{modules});
    $self->build_mirror_file($index, $self->{mirror_file});

    $self->run_cpanm(
        "--skip-satisfied",
        "--mirror", "http://cpan.cpantesters.org/", # fastest
        "--mirror", "http://backpan.perl.org/",     # fallback
        "--mirror-index", $self->{mirror_file},
        ( $cascade ? "--cascade-search" : () ),
        @$modules,
    );
}

sub build_mirror_file {
    my($self, $index, $file) = @_;

    my @packages = $self->build_packages($index);

    open my $fh, ">", $file or die $!;

    print $fh <<EOF;
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in carton.lock
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Carton $Carton::VERSION
Line-Count:   @{[ scalar(@packages) ]}
Last-Updated: @{[ scalar localtime ]}

EOF
    for my $p (@packages) {
        print $fh sprintf "%s %s  %s\n", pad($p->[0], 32), pad($p->[1] || 'undef', 10, 1), $p->[2];
    }

    return $file;
}

sub pad {
    my($str, $len, $left) = @_;

    my $howmany = $len - length($str);
    return $str if $howmany <= 0;

    my $pad = " " x $howmany;
    return $left ? "$pad$str" : "$str$pad";
}

sub build_packages {
    my($self, $index) = @_;

    my @packages;
    for my $package (sort keys %$index) {
        my $module = $index->{$package};
        push @packages, [ $package, $module->{version}, $module->{meta}{pathname} ];
    }

    return @packages;
}


sub build_index {
    my($self, $modules) = @_;

    my $index;

    for my $name (keys %$modules) {
        my $metadata = $modules->{$name};
        my $provides = $metadata->{provides};
        for my $mod (keys %$provides) {
            $index->{$mod} = { version => $provides->{$mod}, meta => $metadata };
        }
    }

    return $index;
}

sub walk_down_tree {
    my($self, $lock, $cb) = @_;

    require Module::CoreList;

    my %seen;
    my $tree = $self->build_tree($lock->{modules});
    $tree->walk_down(sub {
        my($node, $depth, $parent) = @_;
        return $tree->abort if $seen{$node->key}++;

        if ($node->metadata->{dist}) {
            $cb->($node->metadata, $depth);
        } elsif (!$Module::CoreList::version{$]+0}{$node->key}) {
            warn "Couldn't find ", $node->key, "\n";
        }
    });
}

sub build_tree {
    my($self, $modules) = @_;

    my $idx  = $self->build_index($modules);
    my $pool = { %$modules }; # copy

    my $tree = Carton::Tree->new;

    while (my $pick = (keys %$pool)[0]) {
        $self->_build_tree($pick, $tree, $tree, $pool, $idx);
    }

    $tree->finalize;

    return $tree;
}

sub _build_tree {
    my($self, $elem, $tree, $curr_node, $pool, $idx) = @_;

    if (my $cached = Carton::TreeNode->cached($elem)) {
        $curr_node->add_child($cached);
        return;
    }

    my $node = Carton::TreeNode->new($elem, $pool);
    $curr_node->add_child($node);

    for my $child ( $self->build_deps($node->metadata, $idx) ) {
        $self->_build_tree($child, $tree, $node, $pool, $idx);
    }
}

sub build_deps {
    my($self, $meta, $idx) = @_;

    my @deps;
    for my $requires (values %{$meta->{requires}}) {
        for my $module (keys %$requires) {
            next if $module eq 'perl';
            if (exists $idx->{$module}) {
                push @deps, $idx->{$module}{meta}{name};
            } else {
                push @deps, $module;
            }
        }
    }

    return @deps;
}

sub run_cpanm_output {
    my($self, @args) = @_;

    my $pid = open(my $kid, "-|"); # XXX portability
    if ($pid) {
        return <$kid>;
    } else {
        local $ENV{PERL_CPANM_OPT};
        exec $self->{cpanm}, "--quiet", "-L", $self->{path}, @args;
    }
}

sub run_cpanm {
    my($self, @args) = @_;
    local $ENV{PERL_CPANM_OPT};
    !system $self->{cpanm}, "--quiet", "-L", $self->{path}, "--notest", @args;
}

sub update_lock_file {
    my($self, $file) = @_;

    my %locals = $self->find_locals;

    my $spec = {
        modules => \%locals,
        perl => $],
        generator => "carton $VERSION",
    };

    require JSON;
    open my $fh, ">", "carton.lock" or die $!;
    print $fh JSON->new->pretty->encode($spec);

    return 1;
}

sub find_locals {
    my $self = shift;

    require File::Find;

    my @locals;
    my $wanted = sub {
        if ($_ eq 'local.json') {
            push @locals, $File::Find::name;
        }
    };
    File::Find::find($wanted, "$self->{path}/lib/perl5/auto/meta");

    return map { my $module = Carton::Util::parse_json($_); ($module->{name} => $module) } @locals;
}

1;

