#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Interface to BBS-based groupware platforms',
    NAME            => 'OurNet',
    DISTNAME        => 'OurNet',
    BINARY_LOCATION => 'x86/OurNet.tar.gz',
    VERSION_FROM    => 'lib/OurNet.pm',

    PREREQ_PM       => {
	'RPC::PlServer'         => '0.2012',     # BBSCOM
	'Net::Telnet'           => '3.02',       # BBSAgent
	'DB_File'               => '1.72',       # FuzzyIndex
	'LWP::Parallel'         => '2.49',       # Query
	'HTTP::Request::Common' => '1.16',       # Query
	'Template'              => '2.00',       # Template, WebBuilder
    }, 

    dist            => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    }
);

