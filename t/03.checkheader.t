# -*- cperl -*-

use Test::More tests => 5;

use Config::AutoConf;

diag("\n\nIgnore junk bellow.\n\n");

## OK, we really hope people have sdtio.h around
ok(Config::AutoConf->check_header("stdio.h"));
ok(!Config::AutoConf->check_header("astupidheaderfile.h"));
is(Config::AutoConf->check_headers("astupidheaderfile.h", "stdio.h"), "stdio.h");

my $ac = Config::AutoConf->new();
eval { $ac->check_default_headers(); };
ok( !$@, "check_default_headers" ) or diag( $@ );
## we should find at least a stdio.h ...
note( "Checking for cache value " . $ac->_cache_name( "stdio.h" ) );
ok( $ac->cache_val( $ac->_cache_name( "stdio.h" ) ), "found stdio.h" );
