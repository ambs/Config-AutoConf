# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 7;

use Config::AutoConf;

END {
  foreach my $f (<config*.*>) {
    -e $f and unlink $f;
  }
}

my ($ac_1, $ac_2);

ok( $ac_1 = Config::AutoConf->new( logfile => "config3.log" ), "Instantiating Config::AutoConf for check_lib() tests" );
ok( $ac_2 = Config::AutoConf->new( logfile => "config4.log" ), "Instantiating Config::AutoConf for search_libs() tests" );

TODO: {
    local $TODO = "It seems some Windows machine doesn't have -lm";

    ## OK, we really hope people have -lm around
    ok($ac_1->check_lib("m", "atan"), "atan() in -lm");
    ok(!$ac_1->check_lib("m", "foobar"), "foobar() not in -lm");

    my $where_atan;
    ok( $where_atan = $ac_2->search_libs( "atan", [qw(m)] ), "searching lib for atan()" );
    isnt( $where_atan, 0, "library for atan() found (or none required)" );
};

TODO: {
  local $TODO = "Quick fix: TODO - analyse diag later";
  my ($fh, $fbuf, $dbuf, $old_logfh);
  $dbuf = "";

  eval "use IO::Tee;";
  unless($@) {
    if ($] < 5.008) {
      require IO::String;
      $fh = IO::String->new($dbuf);
    }
    else {
      open( $fh, "+>", \$dbuf );
    }
    $old_logfh = $ac_1->{logfh};
    my $tee = IO::Tee->new($ac_1->{logfh}, $fh);
    $ac_1->{logfh} = $tee;
  }
  ok( $ac_1->_check_link_perl_api(), "Could link perl extensions" );
  defined $old_logfh and $ac_1->{logfh} = $old_logfh;
  defined $fh and close($fh);
  $fh = undef;
}
