package OurNet::BBS::BBSAgent::BoardGroup;

# XXX BBSAgent support is highly experimental! DO NOT REPLY ON ME!

$OurNet::BBS::BBSAgent::BoardGroup::VERSION = "0.1";

use File::stat;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot bbsobj mtime _cache/;
use OurNet::BBSAgent;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    if (!$self->{bbsobj}) {
        # XXX hack, fixme
        $self->{bbsobj} = OurNet::BBSAgent->new(OurNet::BBS::Utils::locate(
            "$self->{bbsroot}.bbs"
        ) || OurNet::BBS::Utils::locate(
	    "../../BBSAgent/$self->{bbsroot}.bbs"
        ), $OurNet::BBS::TIMEOUT || 30);
        $self->{bbsobj}{debug} = $OurNet::BBS::DEBUG;
        $self->{bbsobj}->login('guest');
        $self->{bbsobj}->main();
    }

    require OurNet::BBS::BBSAgent::Board;

    if ($key) {
        $self->{_cache}{$key} ||= OurNet::BBS::BBSAgent::Board->new(
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
