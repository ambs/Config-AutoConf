package Config::AutoConf;
use ExtUtils::CBuilder;
use 5.008002;

use Config;
use Carp qw/croak/;

use File::Temp qw/tempfile/;
use File::Basename;
use File::Spec;

use Scalar::Util qw/looks_like_number/; # in core since 5.7.3

use base 'Exporter';

our @EXPORT = ('$LIBEXT', '$EXEEXT');

use warnings;
use strict;

# XXX detect HP-UX / HPPA
our $LIBEXT = (defined $Config{dlext}) ? ("." . $Config{dlext}) : ($^O =~ /darwin/i)  ? ".dylib" : ( ($^O =~ /mswin32/i) ? ".dll" : ".so" );
our $EXEEXT = ($^O =~ /mswin32/i) ? ".exe" : "";

=head1 NAME

Config::AutoConf - A module to implement some of AutoConf macros in pure perl.

=cut

our $VERSION = '0.17';

=head1 ABSTRACT

With this module I pretend to simulate some of the tasks AutoConf
macros do. To detect a command, to detect a library, etc.

=head1 SYNOPSIS

    use Config::AutoConf;

    Config::AutoConf->check_prog("agrep");
    my $grep = Config::AutoConf->check_progs("agrep", "egrep", "grep");

    Config::AutoConf->check_header("ncurses.h");
    my $curses = Config::AutoConf->check_headers("ncurses.h","curses.h");

    Config::AutoConf->check_prog_awk;
    Config::AutoConf->check_prog_egrep;

    Config::AutoConf->check_cc();

    Config::AutoConf->check_lib("ncurses", "tgoto");

    Config::AutoConf->check_file("/etc/passwd"); # -f && -r

=head1 FUNCTIONS

=cut

my $glob_instance;

=head2 new

This function instantiates a new instance of Config::AutoConf, eg. to
configure child components.

=cut

sub new {
  my $class = shift;
  ref $class and $class = ref $class;

  my %instance = (
    lang => "C",
    lang_stack => [],
    lang_supported => {
      C => "ExtUtils::CBuilder",
    },
    cache => {},
    defines => {},
  );
  my $self = bless( \%instance, $class );

  return $self;
}

=head2 check_file

This function checks if a file exists in the system and is readable by
the user. Returns a boolean. You can use '-f $file && -r $file' so you
don't need to use a function call.

=cut

sub check_file {
  my $self = shift;
  my $file = shift;

  return (-f $file && -r $file);
}


=head2 check_files

This function checks if a set of files exist in the system and are
readable by the user. Returns a boolean.

=cut

sub check_files {
  my $self = shift;

  for (@_) {
    return 0 unless check_file($self, $_)
  }

  return 1;
}


=head2 check_prog

This function checks for a program with the supplied name. In success
returns the full path for the executable;

=cut

sub check_prog {
  my $self = shift;
  # sanitize ac_prog
  my $ac_prog = _sanitize(shift());
  my $PATH = $ENV{PATH};
  my $p;

	my $ext = "";
	$ext = ".exe" if $^O =~ /mswin/i;
	
  for $p (split /$Config{path_sep}/,$PATH) {
    my $cmd = File::Spec->catfile($p,$ac_prog.$ext);
    return $cmd if -x $cmd;
  }
  return undef;
}

=head2 check_progs

This function takes a list of program names. Returns the full path for
the first found on the system. Returns undef if none was found.

=cut

sub check_progs {
  my $self = shift;
  my @progs = @_;
  for (@progs) {
    my $ans = check_prog($self, $_);
    return $ans if $ans;
  }
  return undef;
}

=head2 check_prog_yacc

From the autoconf documentation,

  If `bison' is found, set [...] `bison -y'.
  Otherwise, if `byacc' is found, set [...] `byacc'. 
  Otherwise set [...] `yacc'.

Returns the full path, if found.

=cut

sub check_prog_yacc {
	my $self = shift;
	my $binary = check_progs(qw/$self bison byacc yacc/);
	$binary .= " -y" if ($binary =~ /bison$/);
	return $binary;
}

=head2 check_prog_awk

From the autoconf documentation,

  Check for `gawk', `mawk', `nawk', and `awk', in that order, and
  set output [...] to the first one that is found.  It tries
  `gawk' first because that is reported to be the best
  implementation.

Note that it returns the full path, if found.

=cut

sub check_prog_awk {
  my $self = shift;
  return check_progs(qw/$self gawk mawk nawk awk/);
}


=head2 check_prog_egrep

From the autoconf documentation,

  Check for `grep -E' and `egrep', in that order, and [...] output
  [...] the first one that is found.

Note that it returns the full path, if found.

=cut

sub check_prog_egrep {
  my $self = shift;

  my $grep;

  if ($grep = check_prog($self,"grep")) {
    my $ans = `echo a | ($grep -E '(a|b)') 2>/dev/null`;
    return "$grep -E" if $ans eq "a\n";
  }

  if ($grep = check_prog($self, "egrep")) {
    return $grep;
  }
  return undef;
}

=head2 check_cc

This function checks if you have a running C compiler.

=cut

sub check_cc {
  ExtUtils::CBuilder->new(quiet => 1)->have_compiler;
}

=head2 checking_msg

Prints "Checking @_ ..."

=cut

sub checking_msg {
  my $self = shift;
  $self->_get_instance()->{quiet} or
    print "Checking " . join( " ", @_, "..." );
  return;
}

=head2 result_msg

Prints result \n

=cut

sub result_msg {
  my $self = shift;
  $self->_get_instance()->{quiet} or
    print join( " ", map { looks_like_number( $_ ) ? ( $_ == 0 ? "no" : ( $_ == 1 ? "yes" : $_ ) ) : $_ } @_ ), "\n";
  return;
}

=head2 define_var( $name, $value [, $comment ] )

Defines a check variable for later use in further checks or code to compile

=cut

sub define_var {
  my $self = shift->_get_instance();
  my ($name, $value, $comment) = @_;

  defined( $name ) or croak( "Need a name to add a define" );

  $self->{defines}->{$name} = [ $value, $comment ];

  return;
}

=head2 compile_if_else( $src [, action-if-true [, action-if-false ] ] )

This function trys to compile specified code and runs action-if-true on success
or action-if-false otherwise.

Returns a boolean value containing check success state.

=cut

sub compile_if_else {
  my ($self, $src, $action_if_true, $action_if_false) = @_;
  ref $self or $self = $self->_get_instance();
  my $builder = $self->_get_builder();

  my ($fh, $filename) = tempfile( "testXXXXXX", SUFFIX => '.c');

  print {$fh} $src;
  close $fh;

  my $obj_file = eval{ $builder->compile(source => $filename) };

  unlink $filename;
  unlink $obj_file if $obj_file;

  if ($@ || !$obj_file) {
    defined( $action_if_false ) and "CODE" eq ref( $action_if_false ) and &{$action_if_false}();
    return 0;
  }

  defined( $action_if_true ) and "CODE" eq ref( $action_if_true ) and &{$action_if_true}();
  return 1;
}

=head2 link_if_else( $src [, action-if-true [, action-if-false ] ] )

This function trys to compile and link specified code and runs action-if-true on success
or action-if-false otherwise.

Returns a boolean value containing check success state.

=cut

sub link_if_else {
  my ($self, $src, $action_if_true, $action_if_false) = @_;
  ref $self or $self = $self->_get_instance();
  my $builder = $self->_get_builder();

  my ($fh, $filename) = tempfile( "testXXXXXX", SUFFIX => '.c');

  print {$fh} $src;
  close $fh;

  my $obj_file = eval{ $builder->compile(source => $filename) };

  if ($@ || !$obj_file) {
    unlink $filename;
    unlink $obj_file if $obj_file;
    defined( $action_if_false ) and "CODE" eq ref( $action_if_false ) and &{$action_if_false}();
    return 0;
  }

  my $exe_file = eval { $builder->link_executable(objects => $obj_file) };

  unlink $filename;
  unlink $obj_file if $obj_file;
  unlink $exe_file if $exe_file;

  if ($@ || !$exe_file) {
    defined( $action_if_false ) and "CODE" eq ref( $action_if_false ) and &{$action_if_false}();
    return 0;
  }

  defined( $action_if_true ) and "CODE" eq ref( $action_if_true ) and &{$action_if_true}();
  return 1;
}

=head2 check_cached( cache-var, message, sub-to-check )

This function checks whether a specified cache variable is set or not, and if not
it's going to set it using specified sub-to-check.

=cut

sub check_cached {
  my ($self, $cache_name, $message, $check_sub) = @_;
  ref $self or $self = $self->_get_instance();

  $self->checking_msg( $message );

  if( defined($self->{cache}->{$cache_name}) ) {
    $self->result_msg( "(cached)", $self->{cache}->{$cache_name} );
  }
  else {
    $self->{cache}->{$cache_name} = &{$check_sub}();
    $self->result_msg( $self->{cache}->{$cache_name} );
  }

  return $self->{cache}->{$cache_name};
}

=head2 cache_val

This functions returns the value of a previously check_cached call.

=cut

sub cache_val {
  my $self = shift->_get_instance();
  my $cache_name = shift;
  defined $self->{cache}->{$cache_name} or return;
  return $self->{cache}->{$cache_name};
}

=head2 check_headers

This function uses check_header to check if a set of include files exist in the system and can
be included and compiled by the available compiler. Returns the name of the first header file found.

=cut

sub check_headers {
  my $self = shift;

  for (@_) {
    return $_ if check_header($self, $_)
  }

  return undef;
}

sub _have_header_define_name {
  my $header = $_[0];
  my $have_name = "HAVE_" . uc($header);
  $have_name =~ tr/_A-Za-z0-9/_/c;
  return $have_name;
}

=head2 check_header

This function is used to check if a specific header file is present in
the system: if we detect it and if we can compile anything with that
header included. Note that normally you want to check for a header
first, and then check for the corresponding library (not all at once).

The standard usage for this module is:

  Config::AutoConf->check_header("ncurses.h");
  
This function will return a true value (1) on success, and a false value
if the header is not present or not available for common usage.

=cut

sub check_header {
  my $self = shift;
  my $header = shift;
  my $pre_inc = shift;
  
  return 0 unless $header;
  my $cache_name = $self->_cache_name( $header );
  my $check_sub = sub {
  
    my $conftest  = $self->_fill_defines();
       $conftest .= $self->_default_includes();
    defined $pre_inc
      and $conftest .= "$pre_inc\n";
       $conftest .= <<"_ACEOF";
    #include <$header>
_ACEOF
       $conftest .= $self->_default_main();

    my $have_header = $self->compile_if_else( $conftest );
    $self->define_var( _have_header_define_name( $header ), $have_header ? $have_header : undef, "defined when $header is available" );

    return $have_header;
  };

  return $self->check_cached( $cache_name, "for $header", $check_sub );
}

=head2 check_all_headers

This function checks each given header for usability.

=cut

sub check_all_headers {
  my $self = shift->_get_instance();
  @_ or return;
  my $rc = 1;
  foreach my $header (@_) {
    $rc &= $self->check_header( $header );
  }
  return $rc;
}

=head2 check_stdc_headers

Checks for standard C89 headers, namely stdlib.h, stdarg.h, string.h and float.h.
If those are found, additional all remaining C89 headers are checked: assert.h,
ctype.h, errno.h, limits.h, locale.h, math.h, setjmp.h, signal.h, stddef.h,
stdio.h and time.h.

=cut

sub check_stdc_headers {
  my $self = shift->_get_instance();
  my $rc = 0;
  if( $rc = $self->check_all_headers( qw(stdlib.h stdarg.h string.h float.h) ) ) {
    $rc &= $self->check_all_headers( qw/assert.h ctype.h errno.h limits.h/ );
    $rc &= $self->check_all_headers( qw/locale.h math.h setjmp.h signal.h/ );
    $rc &= $self->check_all_headers( qw/stddef.h stdio.h time.h/ );
  }
  if( $rc ) {
    $self->define_var( "STDC_HEADERS", 1, "Define to 1 if you have the ANSI C header files." );
  }
  return $rc;
}

=head2 check_default_headers

This function checks for some default headers, the std c89 haeders and
sys/types.h, sys/stat.h, memory.h, strings.h, inttypes.h, stdint.h and unistd.h

=cut

sub check_default_headers {
  my $self = shift->_get_instance();
  my $rc = $self->check_stdc_headers() and $self->check_all_headers( qw(sys/types.h sys/stat.h memory.h strings.h inttypes.h unistd.h) );
  return $rc;
}

=head2 check_lib

This function is used to check if a specific library includes some
function. Call it with the library name (without the lib portion), and
the name of the function you want to test:

  Config::AutoConf->check_lib("z", "gzopen");

It returns 1 if the function exist, 0 otherwise.

=cut

sub check_lib {
  my $self = shift;
  my $lib = shift;
  my $func = shift;

  my $cbuilder = ExtUtils::CBuilder->new(quiet => 1);

  return 0 unless $lib;
  return 0 unless $func;

  # print STDERR "Trying to compile test program to check [$func] on [$lib] library...\n";

  my $LIBS = "-l$lib";
  my $conftest = <<"_ACEOF";
/* Override any gcc2 internal prototype to avoid an error.  */
#ifdef __cplusplus
extern "C"
#endif
/* We use char because int might match the return type of a gcc2
   builtin and then its argument prototype would still apply.  */
char $func ();
int
main ()
{
  $func ();
  return 0;
}
_ACEOF



  my ($fh, $filename) = tempfile( "testXXXXXX", SUFFIX => '.c');
  $filename =~ m!(.*).c$!;
  my $base = $1;

  print {$fh} $conftest;
  close $fh;

  my $obj_file = eval{ $cbuilder->compile(source => $filename) };

  if ($@ || !$obj_file) {
      unlink $filename;
      unlink $obj_file if $obj_file;        
      return 0         
  }

  my $exe_file = eval { $cbuilder->link_executable(objects => $obj_file,
						   extra_linker_flags => $LIBS) };

  unlink $filename;
  unlink $obj_file if $obj_file;
  unlink $exe_file if $exe_file;

  return 0 if $@;
  return 0 unless $exe_file;

  return 1;
}

#
#
# Auxiliary funcs
#

sub _sanitize {
  # This is hard coded, and maybe a little stupid...
  my $x = shift;
  $x =~ s/ //g;
  $x =~ s/\///g;
  $x =~ s/\\//g;
  return $x;
}

sub _get_instance {
  my $class = shift;
  ref $class and return $class;
  defined( $glob_instance ) and ref( $glob_instance ) and return $glob_instance;
  $glob_instance = $class->new();
  return $glob_instance;
}

sub _get_builder {
  my $self = $_[0]->_get_instance();
  defined( $self->{lang_supported}->{ $self->{lang} } ) or croak( "Unsupported compile language \"" . $self->{lang} . "\"" );
  return $self->{lang_supported}->{ $self->{lang} }->new( quiet => 1 );
}

sub _fill_defines {
  my ($self, $src, $action_if_true, $action_if_false) = @_;
  ref $self or $self = $self->_get_instance();

  my $conftest = "";
  while( my ($defname, $defcnt) = each( %{ $self->{defines} } ) ) {
    $defcnt->[0] or next;
    defined $defcnt->[1] and $conftest .= "/* " . $defcnt->[1] . " */\n";
    $conftest .= join( " ", "#define", $defname, $defcnt->[0] ) . "\n";
  }

  return $conftest;
}

#
# default includes taken from autoconf/headers.m4
#

sub _default_includes {
  my $conftest .= <<"_ACEOF";
#include <stdio.h>
#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#ifdef STDC_HEADERS
# include <stdlib.h>
# include <stddef.h>
#else
# ifdef HAVE_STDLIB_H
#  include <stdlib.h>
# endif
#endif
#ifdef HAVE_STRING_H
# if !defined STDC_HEADERS && defined HAVE_MEMORY_H
#  include <memory.h>
# endif
# include <string.h>
#endif
#ifdef HAVE_STRINGS_H
# include <strings.h>
#endif
#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif
_ACEOF

  return $conftest;
}

sub _default_main {
  my $conftest .= <<"_ACEOF";

  /* Override any gcc2 internal prototype to avoid an error.  */
  #ifdef __cplusplus
  extern "C"
  #endif

  int
  main (int argc, char **argv)
  {
    (void)argc;
    (void)argv;
    return 0;
  }    
_ACEOF

  return $conftest;
}

sub _cache_prefix {
  return "ac";
}

sub _cache_name {
  my ($self, $name) = @_;
  my $cache_name = $self->_cache_prefix() . "_cv_" . $name;
     $cache_name =~ tr/_A-Za-z0-9/_/c;
  return $cache_name;
}

=head1 AUTHOR

Alberto Simões, C<< <ambs@cpan.org> >>

Jens Rehsack, C<< < > >>

=head1 NEXT STEPS

Although a lot of work needs to be done, this is the next steps I
intent to take.

  - detect flex/lex
  - detect yacc/bison/byacc
  - detect ranlib (not sure about its importance)

These are the ones I think not too much important, and will be
addressed later, or by request.

  - detect an 'install' command
  - detect a 'ln -s' command -- there should be a module doing
    this kind of task.

=head1 BUGS

A lot. Portability is a pain. B<<Patches welcome!>>.

Please report any bugs or feature requests to
C<bug-extutils-autoconf@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Michael Schwern for kind MacOS X help.

Ken Williams for ExtUtils::CBuilder

=head1 COPYRIGHT & LICENSE

Copyright 2004-2011 by the Authors

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

ExtUtils::CBuilder(3)

=cut

1; # End of Config::AutoConf
