package OurNet::BBS::BBSAgent::Board;
$VERSION = "0.1";

# XXX vote, man, note, etc...
use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board recno mtime _cache/;

BEGIN { __PACKAGE__->initvars() }

sub refresh_articles {
    my $self = shift;

    require OurNet::BBS::BBSAgent::ArticleGroup;

    return $self->{_cache}{articles} ||=
        OurNet::BBS::BBSAgent::ArticleGroup->new(
            $self->{bbsobj}, $self->{board}, 'article'
        );
}

sub refresh_archives {
    die 'archive not implemented';
}

sub refresh_meta {
    die 'metadata not implemented';
}

sub STORE {
    die 'storage not implemented (!)';
}

1;
