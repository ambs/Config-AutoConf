# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 8;
use Config;
use Config::AutoConf;

END { -e "config.log" and unlink "config.log"; }

ok(Config::AutoConf->check_prog("perl"));

ok(!Config::AutoConf->check_prog("hopingnobodyhasthiscommand"));

like(Config::AutoConf->check_progs("___perl___", "__perl__", "_perl_", "perl"), qr/perl(.exe)?$/i);
is(Config::AutoConf->check_progs("___perl___", "__perl__", "_perl_"), undef);	

SKIP: {
  my $awk = Config::AutoConf->check_prog_awk;
  $awk or skip "No awk", 1;
  ok(-x $awk, "$awk is executable");
  diag("Found AWK as $awk");
};

SKIP: {
  my $grep = Config::AutoConf->check_prog_egrep;
  $grep or skip "No egrep", 1;
  ok(-x $grep, "$grep is executable");
  diag("Found EGREP as $grep");
};

SKIP: {
  my $yacc = Config::AutoConf->check_prog_yacc;
  $yacc or skip "No yacc", 1;
  ok(-x $yacc, "$yacc is executable");
  diag("Found YACC as $yacc");
};

SKIP: {
  my $pkg_config = Config::AutoConf->check_prog_pkg_config;
  $pkg_config or skip "No pkg-config", 1;
  ok(-x $pkg_config, "$pkg_config is executable");
  diag("Found PKG-CONFIG as $pkg_config");
};
