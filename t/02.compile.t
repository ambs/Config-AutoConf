# -*- cperl -*-

use Test::More tests => 12;

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
my $include_perl = "#include <EXTERN.h>\n#include <perl.h>";
ok( $ac->check_decl( "PERL_VERSION_STRING", undef, undef, $include_perl ), "PERL_VERSION_STRING declared" );
ok( $ac->check_decls( [qw(PERL_API_REVISION PERL_API_VERSION PERL_API_SUBVERSION)], undef, undef, $include_perl ), "PERL_API_* declared" );
ok( $ac->check_decl( "perl_parse(PerlInterpreter *, XSINIT_t , int , char** , char** )", undef, undef, $include_perl ), "perl_parse() declared" );

# check declared types
ok( $ac->check_type( "I32", undef, undef, $include_perl ), "I32 is valid type" );
ok( $ac->check_types( ["SV *", "AV *", "HV *" ], undef, undef, $include_perl ), "[SAH]V * are valid types" );

# check perl data structure members
ok( $ac->check_member( "struct av.sv_any", undef, undef, $include_perl ), "have struct av.sv_any member" );
ok( $ac->check_members( ["struct hv.sv_any", "struct STRUCT_SV.sv_any"], undef, undef, $include_perl ), "have struct hv.sv_any and struct STRUCT_SV.sv_any members" );
