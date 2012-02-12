use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.008002;

WriteMakefile(
	      NAME          => 'Config::AutoConf',
	      AUTHOR        => 'Alberto Simoes <ambs@cpan.org>',
              LICENSE       => 'perl',
	      VERSION_FROM  => 'lib/Config/AutoConf.pm',
	      ABSTRACT_FROM => 'lib/Config/AutoConf.pm',
	      PL_FILES      => {},
	      PREREQ_PM     => {
				'Capture::Tiny'      => 0,
				'ExtUtils::CBuilder' => 0.23,
				'Test::More'         => 0,
			       },
	      dist          => {
				COMPRESS => 'gzip -9f',
				SUFFIX   => 'gz'
			       },
	      clean         => {
				FILES => 'Config-AutoConf-*'
			       },
	     );
