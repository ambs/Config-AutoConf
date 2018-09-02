#!perl

use strict;
use warnings;

## in a separate test file
use Test::More;

BEGIN
{
    $] >= 5.008 or plan skip_all => "Test::Spelling requires perl 5.8";
}
use Test::Spelling;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
AnnoCPAN
AutoConf
Autoconf
DIR
Dynaloader
Jens
LIBS
MetaCPAN
Perl'ish
Rabbitson
Rehsack
Schwern
ctype
dirlist
inttypes
lang
libm
libperl
libs
llibrary
lm
pkg
pureperl
std
stdarg
stddef
stdint
stdlib
tee'ing
unistd
Simões
getters
preprocessor
refactoring
