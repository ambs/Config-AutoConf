# -*- cperl -*-

use Test::More tests => 8;

use Config::AutoConf;

diag("\n\nIgnore junk bellow.\n\n");

## OK, we really hope people have sdtio.h around
ok(Config::AutoConf->check_header("stdio.h"));
ok(!Config::AutoConf->check_header("astupidheaderfile.h"));
is(Config::AutoConf->check_headers("astupidheaderfile.h", "stdio.h"), "stdio.h");

# check several headers at once
my $ac = Config::AutoConf->new();
eval { $ac->check_default_headers(); };
ok( !$@, "check_default_headers" ) or diag( $@ );
## we should find at least a stdio.h ...
note( "Checking for cache value " . $ac->_cache_name( "stdio.h" ) );
ok( $ac->cache_val( $ac->_cache_name( "stdio.h" ) ), "found stdio.h" );

# check predeclared symbol
# as we test a perl module, we expect perl.h available and suitable
ok( $ac->check_decl( "PERL_VERSION_STRING", undef, undef, "#include <EXTERN.h>\n#include <perl.h>" ), "PERL_VERSION_STRING declared" );
ok( $ac->check_decls( [qw(PERL_API_REVISION PERL_API_VERSION PERL_API_SUBVERSION)], undef, undef, "#include <EXTERN.h>\n#include <perl.h>" ), "PERL_API_* declared" );
ok( $ac->check_decl( "perl_parse(PerlInterpreter *, XSINIT_t , int , char** , char** )", undef, undef, "#include <EXTERN.h>\n#include <perl.h>" ), "perl_parse() declared" );
