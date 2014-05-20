#!perl

use strict;
use warnings;

use Test::More;
use File::Copy;
BEGIN { !-f "META.yml" and copy("MYMETA.yml", "META.yml"); }
END { -f "META.yml" and unlink "META.yml"; }
use Test::Kwalitee;
