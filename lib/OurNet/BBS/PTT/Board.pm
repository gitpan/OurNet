package OurNet::BBS::PTT::Board;
$VERSION = "0.1";
use fields qw/_cache/;
use base qw/OurNet::BBS::MAPLE2::Board/;
$backend = 'PTT';
$packstring = 'Z13Z49Z39LZ3LZ3CLLLLZ120';
$packsize = 120;
@packlist = qw/id title bm brdattr pad bupdate pad2 bvote vtime level uid gid pad3/;

1;
