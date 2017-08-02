# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 9;

use Config::AutoConf;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

END
{
    foreach my $f (<config*.*>)
    {
        -e $f and unlink $f;
    }
}

my $pkg_config = Config::AutoConf->check_prog_pkg_config;

SKIP:
{
    $pkg_config or skip "No pkg-config", 1;
    local $ENV{PKG_CONFIG_PATH} = File::Spec->catdir(dirname(abs_path($0)), "testdata");
    my $ac = Config::AutoConf->new(logfile => "config5.log");
    my $foo_flags = $ac->pkg_config_package_flags("foo");
    is($foo_flags, "-I/base/path/include/foo-0 -L/base/path/lib/foo -lfoo", "pkg-config flags for 'foo'");
}

SCOPE:
{
    # this section intensionally works without pkg-config binary
    local $ENV{bar_CFLAGS} = "-Ibar";
    local $ENV{bar_LIBS}   = "-lbar";
    my $ac = Config::AutoConf->new(
        logfile      => "config5.log",
        logfile_mode => ">>"
    );
    my $bar_flags = $ac->pkg_config_package_flags("bar>2");
    is($bar_flags, "-Ibar -lbar", "pkg-config flags for 'bar>2'");
    my $cache_name = $ac->_cache_name(qw/pkg bar/);
    ok($ac->{cache}->{$cache_name}, "cache entry for 'bar>2' computed correctly");
}

SCOPE:
{
    local $ENV{PERL_MM_OPT} = "PUREPERL_ONLY=0";
    local $0 = "Makefile.PL";
    my $ac = Config::AutoConf->new(
        logfile      => "config6.log",
        logfile_mode => ">>"
    );
    ok(!$ac->check_pureperl_required(), "PERL_MM_OPT=\"PUREPERL_ONLY=0\" Makefile.PL");
}

SCOPE:
{
    local $ENV{PERL_MM_OPT} = "PUREPERL_ONLY=1";
    local $0 = "Makefile.PL";
    my $ac = Config::AutoConf->new(
        logfile      => "config6.log",
        logfile_mode => ">>"
    );
    ok($ac->check_pureperl_required(), "PERL_MM_OPT=\"PUREPERL_ONLY=1\" Makefile.PL");
}

SCOPE:
{
    local $0 = "Makefile.PL";
    my $ac = Config::AutoConf->new(
        logfile      => "config6.log",
        logfile_mode => ">>"
    );
    $ac->_set_argv("PUREPERL_ONLY=0");
    ok(!$ac->check_pureperl_required(), "Makefile.PL PUREPERL_ONLY=0");
}

SCOPE:
{
    local $0 = "Makefile.PL";
    my $ac = Config::AutoConf->new(
        logfile      => "config6.log",
        logfile_mode => ">>"
    );
    $ac->_set_argv("PUREPERL_ONLY=1");
    ok($ac->check_pureperl_required(), "Makefile.PL PUREPERL_ONLY=1");
}

SCOPE:
{
    local $0 = "Build.PL";
    my $ac = Config::AutoConf->new(
        logfile      => "config6.log",
        logfile_mode => ">>"
    );
    $ac->_set_argv("--pureperl-only");
    ok($ac->check_pureperl_required(), "Build.PL --pureperl-only");
}

SCOPE:
{
    local $0 = "Build.PL";
    local $ENV{PERL_MB_OPT} = "--pureperl-only";
    my $ac = Config::AutoConf->new(
        logfile      => "config6.log",
        logfile_mode => ">>"
    );
    ok($ac->check_pureperl_required(), "PERL_MB_OPT=\"--pureperl-only\" ");
}
