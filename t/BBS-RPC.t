use strict;
use Test;
use OurNet::BBS;
use OurNet::BBS::PlClient;

BEGIN { plan tests => 4 }

mkdir '/tmp';
my $prefix = "/tmp/".rand();
OurNet::BBS::Utils::deltree($prefix);
mkdir $prefix or die "Cannot make $prefix";
mkdir "$prefix/$_" or die "Cannot make $prefix/$_"
    foreach ('bbs', 'bbs/boards', 'bbs/group', 'bbs/man', 'bbs/man/boards');

open(BOARDS, ">$prefix/bbs/.BOARDS")
    or die "Cannot make $prefix/bbs/.BOARDS : $!";
close BOARDS;
    
if (fork()) {
    my $BBS;
    ok($BBS = OurNet::BBS->new('CVIC', "$prefix/bbs"));

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
} else {
    my $count = 0;
    while ($count++ < 5 and not -e "$prefix/bbs/boards/test/.DIR") {
        sleep 1;
    }
    my $brd = OurNet::BBS::PlClient->new('localhost', 2000);
    sleep 1;
    $brd->{bm} = $brd->{title};
    sleep 1;
    my $art = $brd->{articles};
    $art->[1]{title} = "elephant";
}

