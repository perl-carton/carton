package Carton;

use strict;
use warnings;
use 5.008_005;
use version; our $VERSION = version->declare("v0.9.50");

use Cwd;
use Config qw(%Config);
use Carton::Util;
use CPAN::Meta;
use CPAN::Meta::Requirements;
use File::Path ();
use File::Spec ();
use File::Temp ();
use Capture::Tiny 'capture';
use Module::CPANfile;

use constant CARTON_LOCK_VERSION => '0.9';
our $DefaultMirror = 'http://cpan.metacpan.org/';

sub new {
    my($class, %args) = @_;
    bless {
        path => $ENV{PERL_CARTON_PATH} || 'local',
        mirror => $ENV{PERL_CARTON_MIRROR} || $DefaultMirror,
    }, $class;
}

sub use_local_mirror {
    my $self = shift;
    $self->{mirror} = $self->local_cache;
}

sub local_cache {
    File::Spec->rel2abs("$_[0]->{path}/cache");
}

sub list_dependencies {
    my $self = shift;

    my $cpanfile = Module::CPANfile->load;
    my $prereq = $cpanfile->prereq;

    my $reqs = CPAN::Meta::Requirements->new;
    $reqs->add_requirements($prereq->requirements_for($_, 'requires'))
        for qw( configure build runtime test );

    my $hash = $reqs->as_string_hash;
    # TODO refactor to not rely on string representation
    # TODO actually check 'perl' version
    return map "$_~$hash->{$_}", grep { $_ ne 'perl' } keys %$hash;
}

sub bundle {
    my($self, $cpanfile, $lock) = @_;

    my @modules = $self->list_dependencies;
    $lock->write_index($self->{mirror_file});

    my $mirror = $self->{mirror} || $DefaultMirror;
    my $local_cache = $self->local_cache; # because $self->{path} is localized
    local $self->{path} = File::Temp::tempdir(CLEANUP => 1); # ignore installed

    $self->run_cpanm(
        "--mirror", $mirror,
        "--mirror", "http://backpan.perl.org/", # fallback
        "--mirror-index", $self->{mirror_file},
        "--skip-satisfied",
        "--cascade-search",
        ( $mirror ne $DefaultMirror ? "--mirror-only" : () ),
        "--save-dists", $local_cache,
        @modules,
    );
}

sub install {
    my($self, $file, $lock, $cascade) = @_;

    my @modules = $self->list_dependencies;

    if ($lock) {
        $lock->write_index($self->{mirror_file});
    }

    my $mirror = $self->{mirror} || $DefaultMirror;

    my $is_default_mirror = 0;
    if ( !ref $mirror ) {
        $is_default_mirror = $mirror eq $DefaultMirror ? 1 : 0;
        $mirror = [split /,/, $mirror];
    }

    $self->run_cpanm(
        (map { ("--mirror", $_) } @{$mirror}),
        "--mirror", "http://backpan.perl.org/", # fallback
        "--skip-satisfied",
        ( $is_default_mirror ? () : "--mirror-only" ),
        ( $lock ? ("--mirror-index", $self->{mirror_file}) : () ),
        ( $cascade ? "--cascade-search" : () ),
        @modules,
    ) or die "Installing modules failed\n";
}

sub build_index {
    my($self, $lock) = @_;

    my $index;

    while (my($name, $metadata) = each %{$lock->{modules}}) {
        for my $mod (keys %{$metadata->{provides}}) {
            $index->{$mod} = { %{$metadata->{provides}{$mod}}, meta => $metadata };
        }
    }

    return $index;
}

sub is_core {
    my($self, $module, $want_ver, $perl_version) = @_;
    $perl_version ||= $];

    require Module::CoreList;
    my $is_core  = exists $Module::CoreList::version{$perl_version + 0}{$module}
        or return;

    my $core_ver = $Module::CoreList::version{$perl_version + 0}{$module};
    return 1 unless $want_ver;
    return version->new($core_ver) >= version->new($want_ver);
};

sub merge_prereqs {
    my($self, $prereqs) = @_;

    my %requires;
    for my $phase (qw( configure build test runtime )) {
        %requires = (%requires, %{$prereqs->{$phase}{requires} || {}});
    }

    return \%requires;
}

sub build_deps {
    my($self, $meta, $idx) = @_;

    my $requires = $self->merge_prereqs($meta->{mymeta}{prereqs});

    my @deps;
    for my $module (keys %$requires) {
        next if $module eq 'perl';
        if (exists $idx->{$module}) {
            push @deps, $idx->{$module}{meta}{name};
        } else {
            push @deps, $module;
        }
    }

    return @deps;
}

sub run_cpanm {
    my($self, @args) = @_;
    local $ENV{PERL_CPANM_OPT};
    !system "cpanm", "--quiet", "-L", $self->{path}, "--notest", @args;
}

sub update_lock_file {
    my($self, $file) = @_;

    my $lock = $self->build_lock;
    Carton::Lock->new($lock)->write($file);

    return 1;
}

sub build_lock {
    my $self = shift;

    my %installs = $self->find_installs;

    return {
        modules => \%installs,
        version => CARTON_LOCK_VERSION,
    };
}

sub find_installs {
    my $self = shift;

    require File::Find;

    my $libdir = "$self->{path}/lib/perl5/$Config{archname}/.meta";
    return unless -e $libdir;

    my @installs;
    my $wanted = sub {
        if ($_ eq 'install.json') {
            push @installs, [ $File::Find::name, "$File::Find::dir/MYMETA.json" ];
        }
    };
    File::Find::find($wanted, $libdir);

    return map {
        my $module = Carton::Util::load_json($_->[0]);
        my $mymeta = -f $_->[1] ? CPAN::Meta->load_file($_->[1])->as_struct({ version => "2" }) : {};
        ($module->{name} => { %$module, mymeta => $mymeta }) } @installs;
}

sub check_satisfies {
    my($self, $lock, $deps) = @_;

    my @unsatisfied;
    my $index = $self->build_index($lock);
    my %pool = %{$lock->{modules}}; # copy

    my @root = map { [ split /~/, $_, 2 ] } @$deps;

    for my $dep (@root) {
        $self->_check_satisfies($dep, \@unsatisfied, $index, \%pool);
    }

    return {
        unsatisfied => \@unsatisfied,
    };
}

sub _check_satisfies {
    my($self, $dep, $unsatisfied, $index, $pool) = @_;

    my($mod, $ver) = @$dep;

    my $found = $index->{$mod};
    if ($found) {
        delete $pool->{$found->{meta}{name}};
    } elsif ($self->is_core($mod, $ver)) {
        return;
    }

    unless ($found and (!$ver or version->new($found->{version}) >= version->new($ver))) {
        push @$unsatisfied, {
            module => $mod,
            version => $ver,
            found => $found ? $found->{version} : undef,
        };
        return;
    }

    my $requires = $self->merge_prereqs($found->{meta}{mymeta}{prereqs});
    for my $module (keys %$requires) {
        next if $module eq 'perl';
        $self->_check_satisfies([ $module, $requires->{$module} ], $unsatisfied, $index, $pool);
    }
}

1;
__END__

=head1 NAME

Carton - Perl module dependency manager (aka Bundler for Perl)

=head1 SYNOPSIS

  # On your development environment
  > cat cpanfile
  requires 'Plack', 0.9980;
  requires 'Starman', 0.2000;
  
  > carton install
  > git add cpanfile carton.lock
  > git commit -m "add Plack and Starman"

  # Other developer's machine, or on a deployment box
  > carton install
  > carton exec -Ilib -- starman -p 8080 myapp.psgi

=head1 WARNING

B<This software is under heavy development and considered ALPHA
quality till its version hits v1.0.0. Things might be broken, not all
features have been implemented, and APIs are likely to change. YOU
HAVE BEEN WARNED.>

=head1 DESCRIPTION

carton is a command line tool to track the Perl module dependencies
for your Perl application. The managed dependencies are tracked in a
I<carton.lock> file, which is meant to be version controlled, and the
lock file allows other developers of your application will have the
exact same versions of the modules.

=head1 TUTORIAL

=head2 Initializing the environment

carton will use the I<.carton> directory for local configuration and
the I<local> directory to install modules into. You're recommended to
exclude these directories from the version control system.

  > echo .carton/ >> .gitignore
  > echo local/ >> .gitignore
  > git add carton.lock
  > git commit -m "Start using carton"

=head2 Tracking the dependencies

You can manage the dependencies of your application via I<cpanfile>.

  # cpanfile
  requires 'Plack', 0.9980;
  requires 'Starman', 0.2000;

And then you can install these dependencies via:

  > carton install

The modules are installed into your I<local> directory, and the
dependencies tree and version information are analyzed and saved into
I<carton.lock> in your directory.

Make sure you add I<carton.lock> to your version controlled repository
and commit changes as you update dependencies. This will ensure that
other developers on your app, as well as your deployment environment,
use exactly the same versions of the modules you just installed.

  > git add cpanfile carton.lock
  > git commit -m "Added Plack and Starman"

=head2 Deploying your application

Once you've done installing all the dependencies, you can push your
application directory to a remote machine (excluding I<local> and
I<.carton>) and run the following command:

  > carton install

This will look at the I<carton.lock> and install the exact same
versions of the dependencies into I<local>, and now your application
is ready to run.

=head2 Bundling modules

carton can bundle all the tarballs for your dependencies into a
directory so that you can even install dependencies that are not
available on CPAN, such as internal distribution aka DarkPAN.

  > carton bundle

will bundle these tarballs into I<local/cache> directory, and

  > carton install --cached

will install modules using this local cache. This way you can avoid a
dependency on CPAN meta DB and search.cpan.org at a deploy time, or
you can have dependencies onto private CPAN modules aka DarkPAN.

=head1 COMMUNITY

=over 4

=item L<https://github.com/miyagawa/carton>

Code repository, Wiki and Issue Tracker

=item L<irc://irc.perl.org/#carton>

IRC chat room

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 COPYRIGHT

Tatsuhiko Miyagawa 2011-

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<cpanm>

L<Bundler|http://gembundler.com/>

L<pip|http://pypi.python.org/pypi/pip>

L<npm|http://npmjs.org/>

L<perlrocks|https://github.com/gugod/perlrocks>

L<only>

=cut
