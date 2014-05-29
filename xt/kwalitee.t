#!perl

use strict;
use warnings;

use Test::More;
BEGIN {
  $] >= 5.010 or plan skip_all => "Test::Kwalitee requires perl 5.10 (at least on AUTHOR's machine ^^)";
}
use File::Copy;
BEGIN { !-f "META.yml" and copy("MYMETA.yml", "META.yml"); }
END { -f "META.yml" and unlink "META.yml"; }
use Test::Kwalitee;
