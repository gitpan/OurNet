package OurNet::BBS::MAPLE2::SessionGroup;

$OurNet::BBS::MAPLE2::SessionGroup::VERSION = "0.1";

use strict;
use File::stat;
use OurNet::BBS::ShmScalar;
use POSIX;

use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot shmkey maxsession chatport shmid shm _cache/;
use vars qw/$packstring $packsize @packlist/;

my %registered; # registered callbacks
my %instances;  # object instances

$packstring = 'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64LCx3a1000LL';
$packsize   = 1476;
@packlist   = qw/uid pid sockaddr destuid destuip active invisible 
                 sockactive userlevel mode pager in_chat sig userid 
                 chatid realname username from tty friends reject 
                 uptime msgcount msgs mood site/;

sub message_handler {
    # we don't handle multiple messages in the queue yet.
    foreach my $instance (values %instances) {
	print "check for instance $instance\n";
        $instance->refresh_meta($_)
            foreach (0..$instance->{maxsession}-1);

        foreach my $session (values %{$registered{$instance}}) {
	    print "check for $session->{_cache}{pid}\n";
	    $session->refresh_meta();
	    if ($session->{_cache}{msgcount}) {
		my ($pid, $userid, $message) = 
		    unpack('LZ13Z80x3', $session->{_cache}{msgs});
		my $from = $pid && (grep {$_->{pid} == $pid} 
		    @{$instance->{_cache}}{0..$instance->{maxsession}-1})[0];
		print "pid $pid, from $from\n";
		$session->dispatch($from || $userid, $message);
	    }
	}
    }
    $SIG{USR2} = \&message_handler;
};

$SIG{USR2} = \&message_handler;

sub _lock {
    
}

sub _unlock {

}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $packsize = $self->getvar('SessionGroup::packsize');

    unless ($self->{shmid} || !$self->{shmkey}) {
        # print "ASDSKD\n";
        if ($^O ne 'MSWin32' and
            $self->{shmid} = shmget($self->{shmkey}, 
				    ($self->{maxsession})*$packsize+36, 0)) {
            tie $self->{shm}{uptime}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxsession}*$packsize, 4, 'L';
            tie $self->{_cache}{number}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxsession}*$packsize+4, 4, 'L';
            tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxsession}*$packsize+8, 4, 'L';
	    $instances{$self} = $self;
        }
    }
    # print "[BoardGroup] no shm support" unless $self->{shm};
    if ($key eq int($key)) {
        print "new toy called $key\n" unless $self->{_cache}{$key};
        $registered{$self} ||= {};
        $self->{_cache}{$key} ||= $self->module('Session')->new(
            $self->{bbsroot},
            $key,
            $self->{shmid},
            $self->{shm},
            $self->{chatport},
	    $registered{$self}, 
        );
        return;
    }
}

sub STORE {
    my ($self, $key, $value) = @_;

    die "STORE: attempt to store non-hash value ($value) into ".ref($self)
	unless UNIVERSAL::isa($value, 'HASH');

    unless (length($key)) {
	print "trying to create new session\n";
        undef $key;
        for my $newkey (0..$self->{maxsession}-1) {
	    $self->refresh_meta($newkey);
	    ($key ||= $newkey, last) if $self->{_cache}{$newkey}{pid} < 2;
	}
        print "new key $key...\n";
    }

    die "no more session $key" unless defined $key;

    ++$self->{_cache}{number};
    $self->refresh_meta($key);
    %{$self->{_cache}{$key}} = %{$value};

}

sub DESTROY {
    my $self = shift;
    delete $instances{$self};
}

1;
