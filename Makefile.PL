#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Interface to BBS-based groupware platforms',
    NAME            => 'OurNet',
    DISTNAME        => 'OurNet',
    BINARY_LOCATION => 'x86/OurNet.tar.gz',
    VERSION_FROM    => 'OurNet.pm',

    PREREQ_PM       => {
        'OurNet::FuzzyIndex'    => '1.51',
        'OurNet::Site'          => '1.21',
        'OurNet::BBS'           => '1.51',
        'OurNet::BBSAgent'      => '1.51',
        'OurNet::BBSApp'        => '0.02',
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
    $content =~ s/\n\]\n/\n\n/g;
    close _;
    open _, '>Makefile' or exit;
    print _ $content;
}


