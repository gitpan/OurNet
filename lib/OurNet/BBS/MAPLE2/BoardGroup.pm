package OurNet::BBS::MAPLE2::BoardGroup;

$OurNet::BBS::MAPLE2::BoardGroup::VERSION = "0.1";

use File::stat;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot shmkey maxboard shmid shm mtime _cache/;
use vars qw/$backend/;
use OurNet::BBS::ShmScalar;

$backend = 'MAPLE2';

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/.BOARDS";
    my $board;

    unless ($self->{shmid} || !$self->{shmkey}) {
        if ($^O ne 'MSWin32' and
            $self->{shmid} = shmget($self->{shmkey}, $self->{maxboard}*128+8, 0)) {
            tie $self->{shm}{touchtime}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxboard}*128+4, 4, 'L';
            tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
                $self->{shmid}, $self->{maxboard}*128+12, 4, 'L';
        }
    }
    # print "[BoardGroup] no shm support" unless $self->{shm};
    require "OurNet/BBS/${backend}/Board.pm";

    if ($key) {
        $self->{_cache}{$key} ||= "OurNet::BBS::${backend}::Board"->new(
            $self->{bbsroot},
            $key,
            $self->{shmid},
            $self->{shm}
        );
        return;
    }

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};
    $self->{mtime} = stat($file)->mtime;

    open DIR, "$file" or die "can't read DIR file for $self->{board}: $!";

    foreach (0..int(stat($file)->size / 128)-1) {
        seek DIR, 128 * $_, 0;
        read DIR, $board, 13;
        $board = unpack('Z13', $board);
        next unless $board and substr($board,0,1) ne "\0";
        $self->{_cache}{$board} ||= "OurNet::BBS::${backend}::Board"->new(
            $self->{bbsroot},
            $board,
            $self->{shmid},
            $self->{shm},
            $_,
        );
    }

    close DIR;
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});

    my $file = "$self->{bbsroot}/.BOARDS";
    return 0 if $self->{mtime} and stat($file)->mtime == $self->{mtime};

    open DIR, $file or die "can't read DIR file $file: $!";

    my $board;
    foreach (0..int(stat($file)->size / 128)-1) {
        seek DIR, 128 * $_, 0;
        read DIR, $board, 13;
        return 1 if unpack('Z13', $board) eq $key;
    }

    close DIR;
    return 0;
}

sub STORE {
    my $self = shift;
    my $key  = shift;

    die "Need key for STORE" unless $key;

    foreach my $value (@_) {
        die "STORE: attempt to store non-hash value ($value) into ".ref($self)
            unless UNIVERSAL::isa($value, 'HASH');

        my $class  = (UNIVERSAL::isa($value, "UNIVERSAL"))
            ? ref($value) : "OurNet::BBS::${backend}::Board";
        my $module = "$class.pm";

        $module =~ s|::|/|g;
        require $module;

        %{$class->new(
            $self->{bbsroot},
            $key,
        )} = %{$value};
    }
}

1;
