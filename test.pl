#!/usr/bin/perl -w
use strict;
use Test;

BEGIN {
    my @modules = qw/BBS BBSApp BBSAgent ChatBot FuzzyIndex
		    Query Site Template WebBuilder/;

    plan tests => @modules + 1;

    use OurNet;
    ok(1);

    foreach my $mod (@modules) {
	eval "use OurNet::$mod";
	ok(!$@);
    }
}
