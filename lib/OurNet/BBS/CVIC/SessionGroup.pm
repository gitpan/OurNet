package OurNet::BBS::CVIC::SessionGroup;
$VERSION = "0.1";

use base   qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_cache/;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring'    => 'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64Lx13Cx2a1000LL',
        '$packsize'      => 1488,
    );
}

1;
