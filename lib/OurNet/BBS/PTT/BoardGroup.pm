package OurNet::BBS::PTT::BoardGroup;
$VERSION = "0.1";

use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_cache _shm _shmid/;
use vars qw/$packstring $packsize @packlist/;

$packstring = 'Z13Z49Z39LZ3LZ3CLLLLZ120';
$packsize = 120;
@packlist = qw/id title bm brdattr pad bupdate pad2 bvote vtime 
               level uid gid pad3/;

1;
