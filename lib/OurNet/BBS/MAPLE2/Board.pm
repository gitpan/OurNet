package OurNet::BBS::MAPLE2::Board;

$OurNet::BBS::MAPLE2::Board::VERSION = "0.1";

# XXX vote, man, note, etc...
use File::stat;
use vars qw/%filemap $backend $packstring $packsize @packlist/;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot board shmid shm recno mtime _cache/;

$backend = 'MAPLE2';
$packstring = 'Z13Z49Z39Z11LZ3CLL';
$packsize = 128;
@packlist = qw/id title bm pad bupdate pad2 bvote vtime level/;

sub refresh_articles {
    my $self = shift;

    require "OurNet/BBS/${backend}/ArticleGroup.pm";

    return $self->{_cache}{articles} ||=
        "OurNet::BBS::${backend}::ArticleGroup"->new(
            $self->{bbsroot}, $self->{board}, 'boards'
        );
}

sub refresh_archives {
    my $self = shift;
    require "OurNet/BBS/${backend}/ArticleGroup.pm";

    return $self->{_cache}{archives} ||=
        "OurNet::BBS::${backend}::ArticleGroup"->new(
            $self->{bbsroot}, $self->{board}, 'man/boards'
        );
}

sub refresh_meta {
    my ($self, $key) = @_;
    die 'cannot parse board' unless $self->{board};

    if ($key and index(" forward anonymous permit notes anonymous access etc_brief ".
                       " maillist overrides reject water notes friendplan",
                       " $key ") > -1) {
        return if exists $self->{_cache}{$key};

        require OurNet::BBS::ScalarFile;
        tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile',
            "$self->{bbsroot}/boards/$self->{board}/$key";

        return 1;
    }

    my $file = "$self->{bbsroot}/.BOARDS";
    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};
    $self->{mtime} = stat($file)->mtime;

    local $/ = \$packsize;
    open DIR, $file or die "can't read .BOARDS: $!";

    if (defined $self->{recno}) {
        seek DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <DIR>);
        if ($self->{_cache}{id} ne $self->{board}) {
            undef $self->{recno};
            seek DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        $self->{recno} = 0;

        while (my $data = <DIR>) {
            @{$self->{_cache}}{@packlist} = unpack($packstring, $data);
            last if ($self->{_cache}{id} eq $self->{board});
            $self->{recno}++;
        }

        if ($self->{_cache}{id} ne $self->{board}) {
            $self->{_cache}{id}       = $self->{board};
            $self->{_cache}{bm}       = '';
            $self->{_cache}{date}     = sprintf("%2d/%02d", (localtime)[4] + 1, (localtime)[3]);
            $self->{_cache}{title}    = '(untitled)';

            mkdir "$self->{bbsroot}/boards/$self->{board}";
            open DIR, ">$self->{bbsroot}/boards/$self->{board}/.DIR";
            close DIR;

            mkdir "$self->{bbsroot}/man/boards/$self->{board}";
            open DIR, ">$self->{bbsroot}/man/boards/$self->{board}/.DIR";
            close DIR;

            open DIR, ">>$file" or die "can't write .BOARDS file for $self->{board}: $!";

            local $^W = 0; # turn off uninitialized warnings
            print DIR pack($packstring, @{$self->{_cache}}{@packlist});

            close DIR;
        }
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    local $^W = 0; # turn off uninitialized warnings

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    return if (index(' '.join(' ', @packlist).' ', " $key ") == -1);

    my $file = "$self->{bbsroot}/.BOARDS";
    open DIR, "+<$file" or die "cannot open $file for writing";
    # print "seeeking to ".($packsize * $self->{recno});
    seek DIR, $packsize * $self->{recno}, 0;
    print DIR pack($packstring, @{$self->{_cache}}{@packlist});
    close DIR;
    $self->{mtime} = stat($file)->mtime;
    $self->{shm}{touchtime} = time() if exists $self->{shm};
}

sub remove {
    my $self = shift;
=emergercy fix
    my $file = "$self->{bbsroot}/.BOARDS";
    open DIR, "+<$file" or die "cannot open $file for writing";
    # print "seeeking to ".($packsize * $self->{recno});
    seek DIR, $packsize * $self->{recno}, 0;
    print DIR "\0" x $packsize;
    close DIR;
=cut

    OurNet::BBS::Utils::deltree("$self->{bbsroot}/boards/$self->{board}");
    OurNet::BBS::Utils::deltree("$self->{bbsroot}/man/boards/$self->{board}");

    return 1;
}

1;
