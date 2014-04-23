# -*- cperl -*-

use Test::More tests => 3;

use Config::AutoConf;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

END { -e "config.log" and unlink "config.log"; }

diag("\n\nIgnore junk below.\n\n");

my $pkg_config = Config::AutoConf->check_prog_pkg_config;

SKIP: {
  $pkg_config or skip "No pkg-config", 1;
  local $ENV{PKG_CONFIG_PATH} = File::Spec->catdir( dirname(abs_path($0)), "testdata" );
  my $foo_flags = Config::AutoConf->pkg_config_package_flags("foo");
  is($foo_flags, "-I/base/path/include/foo-0 -L/base/path/lib/foo -lfoo");
}

SCOPE: {
  # this section intensionally works without pkg-config binary
  local $ENV{bar_CFLAGS} = "-Ibar";
  local $ENV{bar_LIBS} = "-lbar";
  my $bar_flags = Config::AutoConf->pkg_config_package_flags("bar>2");
  is($bar_flags, "-Ibar -lbar");
  my $cache_name = Config::AutoConf->_get_instance()->_cache_name(qw/pkg bar/);
  ok(Config::AutoConf->_get_instance()->{cache}->{$cache_name});
}
