# NAME

Carton - Perl module dependency manager (aka Bundler for Perl)

# SYNOPSIS

    # On your development environment
    > cat cpanfile
    requires 'Plack', '0.9980';
    requires 'Starman', '0.2000';

    > carton install
    > git add cpanfile cpanfile.snapshot
    > git commit -m "add Plack and Starman"

    # Other developer's machine, or on a deployment box
    > carton install
    > carton exec starman -p 8080 myapp.psgi

    # carton exec is optional
    > perl -Ilocal/lib/perl5 local/bin/starman -p 8080 myapp.psgi
    > PERL5LIB=/path/to/local/lib/perl5 /path/to/local/bin/starman -p 8080 myapp.psgi

# AVAILABILITY

Carton only works with perl installation with the complete set of core
modules. If you use perl installed by a vendor package with modules
stripped from core, Carton is not expected to work correctly.

Also, Carton requires you to run your command/application with
`carton exec` command or to include the _local/lib/perl5_ directory
in your Perl library search path (using `PERL5LIB`, `-I`, or
[lib](https://metacpan.org/pod/lib)).

# DESCRIPTION

carton is a command line tool to track the Perl module dependencies
for your Perl application. Dependencies are declared using [cpanfile](https://metacpan.org/pod/cpanfile)
format, and the managed dependencies are tracked in a
_cpanfile.snapshot_ file, which is meant to be version controlled,
and the snapshot file allows other developers of your application will
have the exact same versions of the modules.

For `cpanfile` syntax, see [cpanfile](https://metacpan.org/pod/cpanfile) documentation.

# TUTORIAL

## Initializing the environment

carton will use the _local_ directory to install modules into. You're
recommended to exclude these directories from the version control
system.

    > echo local/ >> .gitignore
    > git add cpanfile cpanfile.snapshot
    > git commit -m "Start using carton"

## Tracking the dependencies

You can manage the dependencies of your application via `cpanfile`.

    # cpanfile
    requires 'Plack', '0.9980';
    requires 'Starman', '0.2000';

And then you can install these dependencies via:

    > carton install

The modules are installed into your _local_ directory, and the
dependencies tree and version information are analyzed and saved into
_cpanfile.snapshot_ in your directory.

Make sure you add _cpanfile_ and _cpanfile.snapshot_ to your version
controlled repository and commit changes as you update
dependencies. This will ensure that other developers on your app, as
well as your deployment environment, use exactly the same versions of
the modules you just installed.

    > git add cpanfile cpanfile.snapshot
    > git commit -m "Added Plack and Starman"

## Specifying a CPAN distribution

You can pin a module resolution to a specific distribution using a
combination of `dist`, `mirror` and `url` options in `cpanfile`.

    # specific distribution on PAUSE
    requires 'Plack', '== 0.9980',
      dist => 'MIYAGAWA/Plack-0.9980.tar.gz';

    # local mirror (darkpan)
    requires 'Plack', '== 0.9981',
      dist => 'MYCOMPANY/Plack-0.9981-p1.tar.gz',
      mirror => 'https://pause.local/';

    # URL
    requires 'Plack', '== 1.1000',
      url => 'https://pause.local/authors/id/M/MY/MYCOMPANY/Plack-1.1000.tar.gz';

## Deploying your application

Once you've done installing all the dependencies, you can push your
application directory to a remote machine (excluding _local_ and
_.carton_) and run the following command:

    > carton install --deployment

This will look at the _cpanfile.snapshot_ and install the exact same
versions of the dependencies into _local_, and now your application
is ready to run.

The `--deployment` flag makes sure that carton will only install
modules and versions available in your snapshot, and won't fallback to
query for CPAN Meta DB for missing modules.

## Bundling modules

carton can bundle all the tarballs for your dependencies into a
directory so that you can even install dependencies that are not
available on CPAN, such as internal distribution aka DarkPAN.

    > carton bundle

will bundle these tarballs into _vendor/cache_ directory, and

    > carton install --cached

will install modules using this local cache. Combined with
`--deployment` option, you can avoid querying for a database like
CPAN Meta DB or downloading files from CPAN mirrors upon deployment
time.

As of Carton v1.0.32, the bundle also includes a package index
allowing you to simply use [cpanm](https://metacpan.org/pod/cpanm) (which has a
[standalone version](https://metacpan.org/pod/App%3A%3Acpanminus#Downloading-the-standalone-executable))
instead of installing Carton on a remote machine.

    > cpanm -L local --from "$PWD/vendor/cache" --installdeps --notest --quiet .

# PERL VERSIONS

When you take a snapshot in one perl version and deploy on another
(different) version, you might have troubles with core modules.

The simplest solution, which might not work for everybody, is to use
the same version of perl in the development and deployment.

To enforce that, you're recommended to use [plenv](https://metacpan.org/pod/plenv) and
`.perl-version` to lock perl versions in development.

You can also specify the minimum perl required in `cpanfile`:

    requires 'perl', '5.16.3';

and carton (and cpanm) will give you errors when deployed on hosts
with perl lower than the specified version.

# COMMUNITY

- [https://github.com/perl-carton/carton](https://github.com/perl-carton/carton)

    Code repository, Wiki and Issue Tracker

# AUTHOR

Tatsuhiko Miyagawa

# COPYRIGHT

Tatsuhiko Miyagawa 2011-

# LICENSE

This software is licensed under the same terms as Perl itself.

# SEE ALSO

[Carmel](https://metacpan.org/pod/Carmel)

[cpanm](https://metacpan.org/pod/cpanm)

[cpanfile](https://metacpan.org/pod/cpanfile)

[Bundler](http://gembundler.com/)

[pip](http://pypi.python.org/pypi/pip)

[npm](http://npmjs.org/)

[perlrocks](https://github.com/gugod/perlrocks)

[only](https://metacpan.org/pod/only)
