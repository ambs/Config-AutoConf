# -*- cperl -*-

use Test::More tests => 21;

use Config::AutoConf;

END {
  -e "config.log" and unlink "config.log";
  -e "config2.log" and unlink "config2.log";
  -e "config.h" and unlink "config.h";
}

diag("\n\nIgnore junk bellow.\n\n");

## OK, we really hope people have sdtio.h around
ok(Config::AutoConf->check_header("stdio.h"));
ok(!Config::AutoConf->check_header("astupidheaderfile.h"));
is(Config::AutoConf->check_headers("astupidheaderfile.h", "stdio.h"), "stdio.h");

# check several headers at once
my $ac = Config::AutoConf->new( logfile => "config2.log" );
eval { $ac->check_default_headers(); };
ok( !$@, "check_default_headers" ) or diag( $@ );
## we should find at least a stdio.h ...
note( "Checking for cache value " . $ac->_cache_name( "stdio.h" ) );
ok( $ac->cache_val( $ac->_cache_name( "stdio.h" ) ), "found stdio.h" );

# some complex header tests for wide OS support
eval { $ac->check_dirent_header(); };
ok( !$@, "check_dirent_header" ) or diag( $@ );

# check predeclared symbol
# as we test a perl module, we expect perl.h available and suitable
my $include_perl = "#include <EXTERN.h>\n#include <perl.h>";

SKIP: {
    skip "Constants not defined on this Perl version", 2 if $] <= 5.01000;

    ok $ac->check_decl( "PERL_VERSION_STRING", undef, undef, $include_perl ),
      "PERL_VERSION_STRING declared";

    ok $ac->check_decls( [qw(PERL_API_REVISION PERL_API_VERSION PERL_API_SUBVERSION)],
                         undef, undef, $include_perl ),
                           "PERL_API_* declared";
}

ok $ac->check_decl( "perl_parse(PerlInterpreter *, XSINIT_t , int , char** , char** )",
                    undef, undef, $include_perl ),
  "perl_parse() declared";

# check declared types
ok $ac->check_type( "I32", undef, undef, $include_perl ),
  "I32 is valid type";

ok $ac->check_types( ["SV *", "AV *", "HV *" ], undef, undef, $include_perl ),
  "[SAH]V * are valid types" ;

# check size of perl types
my $typesize = $ac->check_sizeof_type( "I32", undef, undef, $include_perl );
ok $typesize, "I32 has size of " . ($typesize ? $typesize : "n/a") . " bytes";

ok $ac->check_sizeof_types( ["I32", "SV *", "AV *", "HV *", "SV.sv_refcnt" ], undef, undef, $include_perl ),
  "Could determined sizes for I32, SV *, AV *, HV *, SV.sv_refcnt" ;

my $compute = $ac->compute_int( "-sizeof(I32)", undef, $include_perl );
ok $typesize + $compute == 0, "Compute (-sizeof(I32)";

# check perl data structure members
ok $ac->check_member( "struct av.sv_any", undef, undef, $include_perl ),
  "have struct av.sv_any member";

ok $ac->check_members( ["struct hv.sv_any", "struct STRUCT_SV.sv_any"],
                       undef, undef, $include_perl ),
  "have struct hv.sv_any and struct STRUCT_SV.sv_any members";

Config::AutoConf->write_config_h();
ok( -f "config.h", "default config.h created" );
my $fsize;
ok( $fsize = (stat("config.h"))[7], "config.h contains content" );
$ac->write_config_h();
ok( -f "config.h", "default config.h created" );
cmp_ok( (stat("config.h"))[7], ">", $fsize, "2nd config.h is bigger than first (more checks made)" );

my ($fh, $fbuf, $dbuf);
open( $fh, "<", "config.h" );
{ local $/; $fbuf = <$fh>; }
close( $fh );

open( $fh, "+>", \$dbuf );
$ac->write_config_h( $fh );
close( $fh );

cmp_ok( $dbuf, "eq", $fbuf, "file and direct write computes equal" );
