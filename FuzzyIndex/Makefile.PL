use ExtUtils::MakeMaker;

WriteMakefile(
	NAME           => 'OurNet::FuzzyIndex',
	VERSION_FROM   => 'FuzzyIndex.pm',
#	DEFINE	       => "-DBYPASS",
    XSPROTOARG     => '-noprototypes',
);
