package OurNet::BBS::ShmScalar;
use strict;

sub TIESCALAR {
    my ($class, $shmid, $pos, $sz, $packstr) = @_;
    return bless([$shmid, $pos, $sz, $packstr], $class);
}

sub FETCH {
    my $self = shift;
    my $buf;
    shmread($self->[0], $buf, $self->[1], $self->[2]);
    return unpack($self->[3], $buf);
}

sub STORE {
    my ($self, $value) = @_;
    my $buf = pack($self->[3], $value);
    shmwrite($self->[0], $buf, $self->[1], $self->[2]);
}

1;
