# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 1;
use Config;
use Config::AutoConf;

END { -e "config.log" and unlink "config.log"; }

#
# Let's take REGEXP structure members as of perlreapi
#
my @members = qw/jdd jdd2 engine mother_re extflags minlen minlenret gofs substrs nparens intflags pprivate lastparen lastcloseparen swap offs subbeg saved_copy sublen suboffset subcoffset prelen precomp wrapped wraplen seen_evals paren_names refcnt/;

diag("Check struct regexp");

ok( Config::AutoConf->check_members([ map {"struct regexp.$_"} @members], { prologue => "#include \"EXTERN.h\"
#include \"perl.h\"
#include \"XSUB.h\"" }), "Check struct regexp" );
