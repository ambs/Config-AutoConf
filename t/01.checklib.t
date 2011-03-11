# -*- cperl -*-

use Test::More tests => 2;

use Config::AutoConf;

diag("\n\nIgnore junk bellow.\n\n");

## OK, we really hope people have -lm around
ok(Config::AutoConf->check_lib("m", "atan"));
ok(!Config::AutoConf->check_lib("m", "foobar"));


