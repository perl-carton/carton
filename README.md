# NAME

Carton - Perl module dependency manager (aka Bundler for Perl)

# SYNOPSIS

    # On your development environment
    > cat cpanfile
    requires 'Plack', 0.9980;
    requires 'Starman', 0.2000;

    > carton install
    > git add cpanfile cpanfile.snapshot
    > git commit -m "add Plack and Starman"

    # Other developer's machine, or on a deployment box
    > carton install
    > carton exec starman -p 8080 myapp.psgi

# WARNING

__This software is under heavy development and considered ALPHA
quality till its version hits v1.0.0. Things might be broken, not all
features have been implemented, and APIs are likely to change. YOU
HAVE BEEN WARNED.__

# DESCRIPTION

carton is a command line tool to track the Perl module dependencies
for your Perl application. The managed dependencies are tracked in a
_cpanfile.snapshot_ file, which is meant to be version controlled, and the
snapshot file allows other developers of your application will have the
exact same versions of the modules.

# TUTORIAL

## Initializing the environment

carton will use the _.carton_ directory for local configuration and
the _local_ directory to install modules into. You're recommended to
exclude these directories from the version control system.

    > echo .carton/ >> .gitignore
    > echo local/ >> .gitignore
    > git add cpanfile.snapshot
    > git commit -m "Start using carton"

## Tracking the dependencies

You can manage the dependencies of your application via _cpanfile_.

    # cpanfile
    requires 'Plack', 0.9980;
    requires 'Starman', 0.2000;

And then you can install these dependencies via:

    > carton install

The modules are installed into your _local_ directory, and the
dependencies tree and version information are analyzed and saved into
_cpanfile.snapshot_ in your directory.

Make sure you add _cpanfile.snapshot_ to your version controlled repository
and commit changes as you update dependencies. This will ensure that
other developers on your app, as well as your deployment environment,
use exactly the same versions of the modules you just installed.

    > git add cpanfile cpanfile.snapshot
    > git commit -m "Added Plack and Starman"

## Deploying your application

Once you've done installing all the dependencies, you can push your
application directory to a remote machine (excluding _local_ and
_.carton_) and run the following command:

    > carton install

This will look at the _cpanfile.snapshot_ and install the exact same
versions of the dependencies into _local_, and now your application
is ready to run.

## Bundling modules

carton can bundle all the tarballs for your dependencies into a
directory so that you can even install dependencies that are not
available on CPAN, such as internal distribution aka DarkPAN.

    > carton bundle

will bundle these tarballs into _vendor/cache_ directory, and

    > carton install --cached

will install modules using this local cache. This way you can avoid
querying for a database like CPAN Meta DB or CPAN mirrors upon
deployment time.

# COMMUNITY

- [https://github.com/miyagawa/carton](https://github.com/miyagawa/carton)

    Code repository, Wiki and Issue Tracker

- [irc://irc.perl.org/\#carton](irc://irc.perl.org/\#carton)

    IRC chat room

# AUTHOR

Tatsuhiko Miyagawa

# COPYRIGHT

Tatsuhiko Miyagawa 2011-

# LICENSE

This software is licensed under the same terms as Perl itself.

# SEE ALSO

[cpanm](http://search.cpan.org/perldoc?cpanm)

[Bundler](http://gembundler.com/)

[pip](http://pypi.python.org/pypi/pip)

[npm](http://npmjs.org/)

[perlrocks](https://github.com/gugod/perlrocks)

[only](http://search.cpan.org/perldoc?only)
