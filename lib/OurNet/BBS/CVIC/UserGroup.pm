package OurNet::BBS::CVIC::UserGroup;
$VERSION = "0.1";

use base qw/OurNet::BBS::MAPLE2::UserGroup/;
use fields qw/_cache _phash/;

BEGIN {__PACKAGE__->initvars()};

1;
