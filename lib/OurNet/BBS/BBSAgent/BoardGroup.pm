package OurNet::BBS::BBSAgent::BoardGroup;
$VERSION = "0.1";

# BBSAgent support is still considered experimental. please report bugs.

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot login bbsobj mtime _cache/;
use OurNet::BBSAgent;

BEGIN {
    __PACKAGE__->initvars(
        '$Timeout' => 30,
    )
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    if (!$self->{bbsobj}) {
        # XXX hack, fixme
        $self->{bbsobj} = OurNet::BBSAgent->new(OurNet::BBS::Utils::locate(
            "$self->{bbsroot}.bbs"
        ) || OurNet::BBS::Utils::locate(
            "../../BBSAgent/$self->{bbsroot}.bbs"
        ), $Timeout);
        
        $self->{bbsobj}{debug} = $OurNet::BBS::DEBUG;
        
        if ($self->{login}) {
            $self->{bbsobj}->login(split(':', $self->{login}, 2));
            $self->{bbsobj}{var}{username} ||= (split(':', $self->{login}, 2))[0];
        } else {
            $self->{bbsobj}->login('guest');
            $self->{bbsobj}{var}{username} ||= 'guest';
        }
    }

    if ($key) {
        $self->{_cache}{$key} ||= $self->module('Board')->new(
            $self->{bbsobj},
            $key
        );
        return;
    }

    die 'board listing not implemented';
}

sub EXISTS {
    die 'board listing not implemented';
}

sub STORE {
    die 'board listing not implemented';
}

1;
