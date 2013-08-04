use strict;
use Test::More;
use Carton::Snapshot;
use Carton::Snapshot::Parser;

my $parser = Carton::Snapshot::Parser->new;
my $snapshot = Carton::Snapshot->new; # DUMMY
eval {
    $parser->parse(<<EOM, $snapshot);
# carton snapshot format: version 1.0
DISTRIBUTIONS
  Net-Twitter-Lite-0.12002
    pathname: M/MM/MMIMS/Net-Twitter-Lite-0.12002.tar.gz
    provides:
      Net::Twitter::Lite 0.12002
      Net::Twitter::Lite::API::V1 0.12002
      Net::Twitter::Lite::API::V1_1 0.12002
      Net::Twitter::Lite::Error 0.12002
      Net::Twitter::Lite::WithAPIv1_1 0.12002
    requirements:
      Carp 0
      Crypt::SSLeay 0.5
      Encode 0
      File::Find 0
      File::Temp 0
      HTTP::Request::Common 0
      JSON 2.02
      LWP::UserAgent 2.032
      Module::Build 0.3601
      Net::HTTP >= 0, != 6.04, != 6.05
      Net::Netrc 0
      Test::Fatal 0
      Test::More 0
      Test::Simple 0.98
      URI 1.40
      URI::Escape 0
      overload 0
      parent 0
      perl 5.005
      strict 0
      warnings 0
EOM
};
my $e = $@;
if (! ok !$e, "Should be able to parse") {
    diag "Failed to parse with '$e'";
}
done_testing;