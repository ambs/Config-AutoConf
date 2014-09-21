# -*- cperl -*-

use strict;
use warnings;

use Test::More;

use Config::AutoConf;

END
{
    foreach my $f (<config*.*>)
    {
        -e $f and unlink $f;
    }
}

my ( $ac_1, $ac_2 );

ok( $ac_1 = Config::AutoConf->new( logfile => "config3.log" ), "Instantiating Config::AutoConf for check_lib() tests" );
ok( $ac_2 = Config::AutoConf->new( logfile => "config4.log" ), "Instantiating Config::AutoConf for search_libs() tests" );

ok( $ac_1->check_header("stdio.h") ) or plan skip_all => "No working compile environment";

ok( $ac_1->check_func("printf"), "Every system should have a printf" );
my $set_me;
$ac_1->check_func(
    "scanf",
    {
        action_on_true  => sub { $set_me = 1 },
        action_on_false => sub { $set_me = 0 }
    }
);
ok( defined $set_me, "Having scanf or not, but now we know" );
ok( $ac_1->check_funcs( [qw(sprintf sscanf)] ), "Every system should have sprintf and sscanf" );

TODO:
{
    local $TODO = "It seems some Windows machine doesn't have -lm" if $^O eq "MSWin32";

    ## OK, we really hope people have -lm around
    ok( !$ac_1->check_lib( "m", "foobar" ), "foobar() not in -lm" );
    ok( $ac_1->check_lib( "m", "atan" ), "atan() in -lm" );

    my $where_atan;
    ok( $where_atan = $ac_2->search_libs( "atan", [qw(m)] ), "searching lib for atan()" );
    isnt( $where_atan, 0, "library for atan() found (or none required)" );
}

TODO:
{
    -f "META.yml" or $ENV{AUTOMATED_TESTING} = 1;
    local $TODO = "Quick fix: TODO - analyse diag later" unless $ENV{AUTOMATED_TESTING};
    my ( $fh, $fbuf, $dbuf, @old_logfh );
    $dbuf = "";

    if ( $] < 5.008 )
    {
        require IO::String;
        $fh = IO::String->new($dbuf);
    }
    else
    {
        open( $fh, "+>", \$dbuf );
    }
    @old_logfh = @{ $ac_1->{logfh} };
    $ac_1->add_log_fh($fh);
    cmp_ok( scalar @{ $ac_1->{logfh} }, "==", 2, "Successfully added 2nd loghandle" );
    ok( $ac_1->_check_link_perlapi(), "Could link perl extensions" ) or diag($dbuf);
    scalar @old_logfh and $ac_1->delete_log_fh($fh);
    scalar @old_logfh and is_deeply( \@old_logfh, $ac_1->{logfh}, "add_log_fh/delete_log_fh" );
    defined $fh       and close($fh);
    $fh = undef;
}

done_testing;
