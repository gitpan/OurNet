package OurNet::BBS::MAPLE3::SessionGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE2::SessionGroup/;
use fields qw/_cache/;

BEGIN {
  __PACKAGE__->initvars
    (
     '$packstring'    => 'LLLSSLLLa36Z13Z13Z24Z34',
     '$packsize'      => 152,
     '@packlist'   => 
     [
      qw/pid uid idle_time mode ufo sockaddr sockport destuip msgs userid
	 mateid username from/
     ],
    );
}

1;
