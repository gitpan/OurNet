package OurNet::BBS::MAPLE2::Session;

$OurNet::BBS::MAPLE2::Session::VERSION = "0.1";

use strict;
use vars qw/$backend $packstring $packsize @packlist/;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot recno shmid shm registered myshm _cache/;
use POSIX;

$backend = 'MAPLE2';
$packstring = 'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64LCx3a1000LL';
$packsize = 1476;

@packlist = qw/uid pid sockaddr destuid destuip active invisible sockactive
    userlevel mode pager in_chat sig userid chatid realname username from
    tty friends reject uptime msgcount msgs mood site/;

sub refresh_meta {
    my ($self, $key) = @_;
    my $buf;
    shmread($self->{shmid}, $buf, $packsize*$self->{recno}, $packsize);
    @{$self->{_cache}}{@packlist} = unpack($packstring, $buf);
}

sub _shmwrite {
    my $self = shift;
    shmwrite($self->{shmid}, pack($packstring, @{$self->{_cache}}{@packlist}),
	     $packsize*$self->{recno}, $packsize);
}

sub dispatch {
    my ($self, $from, $message) = @_;

    --$self->{_cache}{msgcount};
    $self->_shmwrite();

    $self->{_cache}{cb_msg} ($from, $message) if $self->{_cache}{cb_msg};
}

sub remove {
    my $self = shift;
    $self->{_cache}{pid} = 0;
    $self->_shmwrite();
    --$self->{shm}{number};
}

sub STORE {
    my ($self, $key, $value) = @_;
    local $^W = 0; # turn off uninitialized warnings

    print "setting $key $value\n";

    if ($key eq 'msg') {
	$self->{_cache}{msgs} = 
	    pack('LZ13Z80', getpid(), $value->[0], $value->[1]);
	$self->{_cache}{msgcount}++;
	kill SIGUSR2, $self->{_cache}{pid};
	$self->_shmwrite();
	return;
    }
    elsif ($key eq 'cb_msg') {
	if (ref($value) eq 'CODE') {
	    print "register callback from $self->{registered}\n";
	    $self->{registered}{$self->{recno}} = $self;
	}
	else {
	    delete $self->{registered}{$self->{recno}};
	}
    }

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    return if (index(' '.join(' ', @packlist).' ', " $key ") == -1);

    $self->_shmwrite();
}

sub DESTROY {
    my $self = shift;
    delete $self->{registered}{$self->{recno}};
}

1;
