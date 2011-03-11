# -*- cperl -*-

use Test::More tests => 3;

use Config::AutoConf;

diag("\n\nIgnore junk bellow.\n\n");

## OK, we really hope people have sdtio.h around
ok(Config::AutoConf->check_header("stdio.h"));
ok(!Config::AutoConf->check_header("astupidheaderfile.h"));
is(Config::AutoConf->check_headers("astupidheaderfile.h", "stdio.h"), "stdio.h");

