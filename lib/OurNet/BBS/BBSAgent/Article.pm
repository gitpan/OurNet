package OurNet::BBS::BBSAgent::Article;

$OurNet::BBS::BBSAgent::Article::VERSION = "0.1";

use File::stat;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board basepath name dir recno mtime btime _cache/;

sub new_id {
    my $self = shift;

    return int($self->{bbsobj}->board_list_last($self->{board}));
}

sub refresh_meta {
    my $self = shift;

    $self->{name} ||= $self->new_id();

    if (defined $self->{recno}) {
        my ($ta, $tb) = $self->{bbsobj}->board_article_fetch_first($self->{board}, $self->{recno});

        while (1) {
            $body .=  $ta;
            # print "fetched ",length($ta),"bytes... [$tb]\n";
            # XXX put special case here
            last unless index($tb, '%') > -1;
            last if ($self->{bbsobj}{bbsname} =~ /cvic/i and index($tb, '100%') > -1);
            
            ($ta, $tb) = $self->{bbsobj}->board_article_fetch_next;
        }
        my ($head, $body) = split(/(?:─)+/, $body, 2);
        my ($author, $nick, $title, $date);

        ($author, $title, $date) = map {
            $head =~ m/\x1b\[47;34m $_ \x1b\[44;37m (.+?)\s*\x1b/ ? $1 : ''
        } ('作者', '標題', '時間'); # This is regex. to hack me: eg. (?:標題|主旨)

        $nick = $1 if $author =~ s/ \((.*)\)//;
        $body =~ s/\n*\x1b\[\d+;1H/\n\n/g;
        $body =~ s/(?<!\015)\012/\015\012/g;
        $body =~ s/\x1b\[32m(.+)\x1b\[m/$1/g;
        $body =~ s/\x1b\[K//g;
        $body =~ s/\x1b\[;H.+\015\012//g;
        my $dt = sprintf("%2d/%02d", int(index('JanFebMarAprMayJunJulAugSepOctNovDec', substr($date,
                4,3))/3 + 1), int(substr($date, 7,3)));

        @{$self->{_cache}}{qw/title author nick body date datetime/} =
            ($title, $author, $nick, $body, $dt, $date);
    }

    unless (defined $self->{recno}) {
        die "New Article: not yet.";
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    die "New Article: not yet.";
}

1;
