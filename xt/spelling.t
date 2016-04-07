#!perl

use strict;
use warnings;

## in a separate test file
use Test::More;

BEGIN {
  $] >= 5.008 or plan skip_all => "Test::Spelling requires perl 5.8";
}
use Test::Spelling;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
AnnoCPAN
Autoconf
AutoConf
Dynaloader
Jens
LIBS
MetaCPAN
Perl'ish
Rabbitson
Rehsack
Schwern
Simões
autoconf
ctype
dirlist
eg
ing
inttypes
lang
libm
libperl
libs
llibrary
lm
preprocessor
pureperl
refactoring
stdarg
stddef
stdint
stdlib
unistd
