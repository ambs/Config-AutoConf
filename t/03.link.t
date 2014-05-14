# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 6;

use Config::AutoConf;

END { -e "config.log" and unlink "config.log"; }

diag("\n\nIgnore junk below.\n\n");

my ($ac_1, $ac_2);

ok( $ac_1 = Config::AutoConf->new(), "Instantiating Config::AutoConf for check_lib() tests" );
ok( $ac_2 = Config::AutoConf->new(), "Instantiating Config::AutoConf for search_libs() tests" );

TODO: {
    local $TODO = "It seems some Windows machine doesn't have -lm";

    ## OK, we really hope people have -lm around
    ok($ac_1->check_lib("m", "atan"), "atan() in -lm");
    ok(!$ac_1->check_lib("m", "foobar"), "foobar() not in -lm");

    my $where_atan;
    ok( $where_atan = $ac_2->search_libs( "atan", [qw(m)] ), "searching lib for atan()" );
    isnt( $where_atan, 0, "library for atan() found (or none required)" );

};
