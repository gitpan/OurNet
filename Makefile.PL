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
        'OurNet::FuzzyIndex'    => '1.52',
        'OurNet::Site'          => '1.52',
        'OurNet::BBS'           => '1.52',
        'OurNet::BBSAgent'      => '1.52',
        'OurNet::BBSApp'        => '0.03',
    },

    dist            => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    }
);

