package OurNet::BBS::MAPLE3::BoardGroup;
$VERSION = "0.1";

use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_cache/;
use vars qw/$packstring $packsize @packlist/;

$packstring = 'Z13Z49Z37CLLLLLLL';
$packsize = 128;
@packlist = qw/id title bm bvote bstamp readlevel postlevel battr btime 
		bpost blast/;

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and
        $self->{shmid} = shmget($self->{shmkey}, $self->{maxboard}*$packsize+8, 0)) {
        tie $self->{shm}{number}, 'OurNet::BBS::ShmScalar',
           $self->{shmid}, $self->{maxboard}*128, 4, 'L';
        tie $self->{shm}{uptime}, 'OurNet::BBS::ShmScalar',
            $self->{shmid}, $self->{maxboard}*128+4, 4, 'L';
    }
    print "shmid = $self->{shmid} number: $self->{shm}{number}\n";
}

1;
