package OurNet::BBS::MAPLE2::GroupGroup;
$VERSION = "0.1";

# do we have group in standard maple2??

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/_cache/;

sub refresh_meta {
    die 'Group for MAPLE2 not implemented.';
}

1;
