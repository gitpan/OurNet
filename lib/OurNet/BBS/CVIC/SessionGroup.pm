package OurNet::BBS::CVIC::SessionGroup;
$VERSION = "0.1";

use base   qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_cache/;
use vars   qw/$packsize $packstring/;

$packsize = 1488;
$packstring = 'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64Lx13Cx2a1000LL';
@packlist   = qw/uid pid sockaddr destuid destuip active invisible 
                 sockactive userlevel mode pager in_chat sig userid 
                 chatid realname username from tty friends reject 
                 uptime msgcount msgs mood site/;

1;
