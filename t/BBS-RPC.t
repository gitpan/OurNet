#!/usr/bin/perl

use strict;
use Test;
use File::Path;

BEGIN { plan tests => 5 }

use OurNet::BBS;
use OurNet::BBS::PlClient;

ok(1);

my $prefix = "/tmp/".rand();

mkpath(["$prefix/boards", "$prefix/group", "$prefix/man/boards"])
    or die "Cannot make $prefix";

open(BOARDS, ">$prefix/.BOARDS") or die "Cannot make $prefix/.BOARDS: $!";
close BOARDS;

if (fork()) {
    my $BBS;
    ok($BBS = OurNet::BBS->new('MAPLE2', $prefix));

    # make a board...
    my $brd = $BBS->{boards}{test} = {
	title => 'test board',
	bm    => 'sysop',
    };
    my $pid;
    push @{$brd->{articles}}, {
        title => 1, author => 2, body => 3
    };
    unless ($pid = fork()) {
        $brd->daemonize(2000);
    }
    my $count = 0;
    while ($count++ < 5 and $brd->{articles}[1]{title} eq '1') {
       sleep 1;
    }
    ok(kill(1, $pid));
    ok($brd->{bm}, $brd->{title});
    ok($brd->{articles}[1]{title}, 'elephant');

    rmtree($prefix);

} else {
    my $count = 0;
    while ($count++ < 5 and not -e "$prefix/boards/test/.DIR") {
        sleep 1;
    }
    my $brd = OurNet::BBS::PlClient->new('localhost', 2000);
    sleep 1;
    $brd->{bm} = $brd->{title};
    sleep 1;
    my $art = $brd->{articles};
    $art->[1]{title} = "elephant";
}

