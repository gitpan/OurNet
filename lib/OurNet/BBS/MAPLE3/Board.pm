package OurNet::BBS::MAPLE3::Board;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_cache/;

sub post_new_board {
    my $self = shift;
    my $dir = "$self->{bbsroot}/boards/$self->{board}/";
    mkdir "$dir$_" foreach (0..9,'A'..'V');
}

1;
