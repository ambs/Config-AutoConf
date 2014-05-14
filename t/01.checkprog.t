# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 8;
use Config;
use Config::AutoConf;

END { -e "config.log" and unlink "config.log"; }

ok( Config::AutoConf->check_prog("perl"), "Find perl" );

ok( !Config::AutoConf->check_prog("hopingnobodyhasthiscommand"), "Don't find ''hopingnobodyhasthiscommand" );

like( Config::AutoConf->check_progs( "___perl___", "__perl__", "_perl_", "perl" ), qr/perl(?:\.exe)?$/i, "Find perl only" );
is( Config::AutoConf->check_progs( "___perl___", "__perl__", "_perl_" ), undef, "Find no _xn surrounded perl" );

sub _is_x {
  $^O =~ m/MSWin32/i and return $_[0] =~ m/\.(?:exe|com|bat|cmd)$/;
  return -x $_[0];
}

SKIP: {
  my $awk = Config::AutoConf->check_prog_awk;
  $awk or skip "No awk", 1;
  my $awk_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $awk )[0];
  ok( _is_x($awk_bin), "$awk_bin is executable" );
  diag("Found AWK as $awk");
}

SKIP: {
  my $grep = Config::AutoConf->check_prog_egrep;
  $grep or skip "No egrep", 1;
  my $grep_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $grep )[0];
  ok( _is_x($grep_bin), "$grep_bin is executable" );
  diag("Found EGREP as $grep");
}

SKIP: {
  my $yacc = Config::AutoConf->check_prog_yacc;
  $yacc or skip "No yacc", 1;
  my $yacc_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $yacc )[0];
  ok( _is_x($yacc_bin), "$yacc is executable" );
  diag("Found YACC as $yacc");
}

SKIP: {
  my $pkg_config = Config::AutoConf->check_prog_pkg_config;
  $pkg_config or skip "No pkg-config", 1;
  ok( _is_x($pkg_config), "$pkg_config is executable" );
  diag("Found PKG-CONFIG as $pkg_config");
}
