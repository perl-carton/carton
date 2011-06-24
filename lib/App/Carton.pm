package App::Carton;

use strict;
use 5.008_001;
use version; our $VERSION = qv('v0.1.0');

use Config;
use Getopt::Long;
use Term::ANSIColor qw(colored);

our $Colors = {
    SUCCESS => 'green',
    INFO    => 'cyan',
    ERROR   => 'red',
};

sub new {
    my $class = shift;
    bless {
        path  => 'extlib',
        color => 1,
        verbose => 0,
        cpanm => $ENV{PERL_CARTON_CPANM} || 'cpanm',
    }, $class;
}

sub run {
    my($self, @args) = @_;

    local @ARGV = @args;
    my @commands;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_ignore_case", "pass_through" ],
    );
    $p->getoptions(
        "h|help"    => sub { unshift @commands, 'help' },
        "v|version" => sub { unshift @commands, 'version' },
        "color!"    => \$self->{color},
        "verbose!"  => \$self->{verbose},
    );

    push @commands, @ARGV;

    my $cmd = shift @commands || 'help';
    my $call = $self->can("cmd_$cmd");

    if ($call) {
        $self->$call(@commands);
    } else {
        die "Could not find command '$cmd'\n";
    }
}

sub parse_options {
    my($self, @opts) = @_;
    Getopt::Long::GetOptionsFromArray(@opts);
}

sub print {
    my($self, $msg, $type) = @_;
    $msg = colored $msg, $Colors->{$type} if $type && $self->{color};
    print $msg;
}

sub check {
    my($self, $msg) = @_;
    $self->print("✓ ", "SUCCESS");
    $self->print($msg . "\n");
}

sub error {
    my($self, $msg) = @_;
    $self->print($msg, "ERROR");
    exit(1);
}

sub cmd_help {
    my $self = shift;
    my $cmd  = $_[0] ? "carton-$_[0]" : "carton";
    system "perldoc", $cmd;
}

sub cmd_version {
    print "carton $VERSION\n";
}

sub cmd_install {
    my($self, @args) = @_;

    $self->parse_options(\@args, "p|path=s", \$self->{path}, "deployment!" => \$self->{deployment});

    if (@args) {
        $self->print("Installing modules from the command line\n");
        $self->install_modules(@args);
        $self->update_packages;
    } elsif (my $file = $self->has_build_file) {
        $self->print("Installing modules using $file\n");
        $self->install_from_build_file($file);
        $self->update_packages;
    } elsif (-e 'carton.json') {
        $self->print("Installing modules using carton.json\n");
        $self->install_from_spec();
    } else {
        $self->error("Can't locate build file or carton.json\n");
    }

    $self->print("Complete! Modules were installed into $self->{path}\n", "SUCCESS");
}

sub has_build_file {
    my $self = shift;

    # deployment mode ignores build files and only uses carton.json
    return if $self->{deployment};

    my $file = (grep -e, qw( Build.PL Makefile.PL ))[0]
        or return;

    if ($self->mtime($file) > $self->mtime("carton.json")) {
        return $file;
    }

    return;
}

sub mtime {
    my($self, $file) = @_;
    return (stat($file))[9] || 0;
}

sub install_from_build_file {
    my($self, $file) = @_;
    $self->run_cpanm("--installdeps", ".");
}

sub install_modules {
    my($self, @args) = @_;
    $self->run_cpanm(@args);
}

sub install_from_spec {
    # build MIRROR index from carton.json and install with cpanm
}

*cmd_list = \&cmd_show;

sub cmd_show {
    my($self, @args) = @_;

    my $data = $self->parse_json('carton.json')
        or $self->error("Can't find carton.json: Run `carton install` to rebuild the spec file.\n");
    for my $module (values %{$data->{modules} || {}}) {
        printf "$module->{dist}\n";
    }
}

sub cmd_check {
    my $self = shift;

    $self->check_cpanm_version;
    # check carton.json and extlib?
}

sub check_cpanm_version {
    my $self = shift;

    my $version = (`$self->{cpanm} --version` =~ /version (\S+)/)[0];
    unless ($version && $version >= 1.5) {
        $self->error("carton needs cpanm version >= 1.5. You have " . ($version || "(not installed)") . "\n");
    }
    $self->check("You have cpanm $version");
}

sub cmd_update {
    # "cleanly" update distributions in extlib
    # rebuild the tree, update modules with DFS
}

sub cmd_exec {
    # setup lib::core::only, -L env, put extlib/bin into PATH and exec script
}

sub run_cpanm {
    my($self, @args) = @_;
    system $self->{cpanm}, "--notest", "--reinstall", "-L", $self->{path}, @args;
}

sub parse_json {
    my($self, $file) = @_;

    open my $fh, "<", $file or return;

    require JSON;
    JSON::decode_json(join '', <$fh>);
}

sub update_packages {
    my $self = shift;

    my %locals = $self->find_locals;

    require JSON;
    open my $fh, ">", "carton.json" or die $!;
    print $fh JSON->new->pretty->encode({ modules => \%locals });

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

    return map { my $module = $self->parse_json($_); ($module->{name} => $module) } @locals;
}

1;
__END__
