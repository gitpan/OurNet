package OurNet::BBS::BBSAgent::Article;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board basepath name dir recno mtime btime _cache/;

BEGIN { __PACKAGE__->initvars() }

sub new_id {
    my $self = shift;

    return int($self->{bbsobj}->board_list_last($self->{board}));
}

sub refresh_meta {
    my $self = shift;
    my $body;
    my $headansi    = $self->{bbsobj}{var}{headansi} || '47;34m';
    my $headansiend = $self->{bbsobj}{var}{headansiend} || '44;37m';

    $self->{name} ||= $self->new_id();

    if (defined $self->{recno}) {
        my ($ta, $tb) = $self->{bbsobj}->board_article_fetch_first($self->{board}, $self->{recno});

        while (1) {
            $body .=  $ta;
            # print "fetched ",length($ta),"bytes... [$tb]\n";
            # XXX put special case here
            last unless index($tb, '%') > -1;
            last if index($tb, '100%') > -1;

            ($ta, $tb) = $self->{bbsobj}->board_article_fetch_next;
        }
        my ($head, $body) = split(/(?:─)+/, $body, 2);
        my ($author, $nick, $title, $date);

        ($author, $title, $date) = map {
            $head =~ m/\x1b\[$headansi $_ \x1b\[$headansiend (.+?)\s*\x1b/ ? $1 : ''
        } ('作者', '標題', '時間'); # This is regex. to hack me: eg. (?:標題|主旨)

        # crude hack section -- this should rule out most ANSI codes but not all
        $nick = $1 if $author =~ s/ \((.*)\)//;

        $body =~ s/\015\012/\n/g; # crlf: whatever native way you feel comfortable
        # $body =~ s/(?<!\015)\012/\015\012/g;
        $body =~ s/\n*\x1b\[\d+;1H/\n\n/g;
        $body =~ s/\x1b\[3[26]m(.+)\x1b\[0?m/$1/g;
        $body =~ s/\x1b\[K//g;
        $body =~ s/\x1b\[;H.+\n//g;
        $body =~ s/\x1b\[H//g;
        $body =~ s/\x1b\[J//g;
        $body =~ s/\n\x1b\[0m\n\n+/\n\n/g; # this is not good. needs tuning.
        $body =~ s/^\x1b\[0m\n\n//g;
        $body =~ s/\n\x1b\[0m$//g;
        $body =~ s/\x00//g;

        use Date::Parse;
        use Date::Format;

        @{$self->{_cache}}{qw/title author nick body date datetime/} =
            ($title, $author, $nick, $body, time2str('%y/%m/%d', str2time($date)), $date);

        my $from = (index($author, '@') > -1)
                   ? $author : "$author.bbs\@$self->{bbsobj}{bbsaddr}";

        $self->{_cache}{header} = {
            From         => $from,
            Subject      => $title,
            Date         => $date,
            'Message-ID' => OurNet::BBS::Utils::get_msgid(
                $date,
                $from,
                $self->{board},
                $self->{bbsobj}{bbsaddr}
            ),
        };

        $self->{bbsobj}->board_article_fetch_last();
    }

    unless (defined $self->{recno}) {
        die "Random creation of article is unimplemented.";
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    
    die "Modify article attributes is unimplemented.";
}

1;
