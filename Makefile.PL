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
    EXE_FILES       => [ <bin/*> ],

    PREREQ_PM       => {
	'File::Path'            => '1.0403',     # test scripts
        'RPC::PlClient'         => '0.2012',     # BBSCOM
	'Net::Telnet'           => '3.02',       # BBSAgent
	'DB_File'               => '1.72',       # FuzzyIndex
	'LWP::Protocol'         => '1.36',       # LWP::Protocol::bbs
	'LWP::Parallel'         => '2.49',       # Query
	'HTTP::Request::Common' => '1.16',       # Query
	'Template'              => '2.00',       # Template, WebBuilder
    }, 

    dist            => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    }
);

# Fix a bug for Win95 nmake
if ($^O =~ /Win32/ and -e 'Makefile') {
    local $/;
    open _, 'Makefile';
    my $content = <_>;
    $content =~ s/\n\@\[\n/\n/g;
    $content =~ s/\n\]\n/\n/g;
    close _;
    open _, '>Makefile' or exit;
    print _ $content;
}


