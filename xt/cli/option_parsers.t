use strict;
use Test::More;
use xt::CLI;

{
    my $app = cli();

    my $install = ["install"];
    $app->parse_carton_options($install);
    is scalar(@$install), 1;
    is $install->[0], "install";

    my $help = ["-h"];
    $app->parse_carton_options($help);
    is scalar(@$help), 1;
    is $help->[0], "help";

    my $help_install = ["-h", "install"];
    $app->parse_carton_options($help_install);
    is scalar(@$help_install), 2;
    is $help_install->[0], "help";
    is $help_install->[1], "install";

    my $help_install_command = ["help", "install"];
    $app->parse_carton_options($help_install_command);
    is scalar(@$help_install_command), 2;
    is $help_install_command->[0], "help";
    is $help_install_command->[1], "install";

    my $version = ["-v"];
    $app->parse_carton_options($version);
    is scalar(@$version), 1;
    is $version->[0], "version";

    my $version_exec = ["-v", "exec"];
    $app->parse_carton_options($version_exec);
    is scalar(@$version_exec), 2;
    is $version_exec->[0], "version";
    is $version_exec->[1], "exec";
}

{
    my $app = cli();

    my $exec_options = ["--system", "--", "perl"];
    my $exec_ret_system;
    my @exec_ret_include;
    my $ret = $app->parse_options($exec_options, 'I=s@', \@exec_ret_include, "system", \$exec_ret_system);
    is $ret, 1;

    is scalar(@exec_ret_include), 0;
    is $exec_ret_system, 1;

    is scalar(@$exec_options), 1;
    is $exec_options->[0], "perl";
}

{
    my $app = cli();
    my $opts = ["-v", "-I", "foo", "--include", "bar", "--help", "--verbose", "executed", "-Iex", "-depth", "1"];
    my $version;
    my $verbose;
    my $help;
    my @include;

    my $ret = $app->parse_options($opts, 'I|include=s@', \@include, 'v|version', \$version, 'verbose!', \$verbose, 'h|help', \$help);
    is $ret, 1;

    is scalar(@include), 2;
    is $include[0], 'foo';
    is $include[1], 'bar';
    is $version, 1;
    is $verbose, 1;
    is $help, 1;

    is scalar(@$opts), 5;
    is $opts->[0], "executed";
    is $opts->[1], "-I"; # options that is same with subcommand are only splitted with name and value
    is $opts->[2], "ex";
    is $opts->[3], "-depth";
    is $opts->[4], "1";
}

{
    my $app = cli();

    my $test_options = ["-v", "perl", "-v"];

    my @ret_include;
    my $ret_version;
    my $ret = $app->parse_options($test_options, 'I=s@', \@ret_include, 'v|version', \$ret_version);
    is $ret, 1;

    is scalar(@ret_include), 0;
    is $ret_version, 1;
    is scalar(@$test_options), 2;

    my $full_options = ["-Ilib", "-I", "extlib/lib/perl5", "--system", "perl", "-cw", "-I", "app/lib", "-e", 'print "OK\n"'];
    my @exec_include;
    my $system;
    my $ret = $app->parse_options($full_options, 'I=s@', \@exec_include, 'system', \$system);
    is $ret, 1;

    is scalar(@exec_include), 2;
    is $exec_include[0], "lib";
    is $exec_include[1], "extlib/lib/perl5";
    is $system, 1;

    is scalar(@$full_options), 6; # "perl", "-cw", "-I", "app/lib", "-e", 'print "OK\n"'
    is $full_options->[0], "perl";
    is $full_options->[1], "-cw";
    is $full_options->[2], "-I";
    is $full_options->[3], "app/lib";
    is $full_options->[4], "-e";
    is $full_options->[5], 'print "OK\n"';
}

done_testing;
