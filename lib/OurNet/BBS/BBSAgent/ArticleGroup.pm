package OurNet::BBS::BBSAgent::ArticleGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board basepath _cache _phash/;

BEGIN { __PACKAGE__->initvars() }

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    if ($key and $key ne int($key)) {
        # hash key -- no recaching needed
        die 'hash key not implemented (!)';
    }

    if ($key) {
        # out-of-bound check
        local $^W = 0; # usage of int() below is voluntary
        return if $key < 1 or $key > int($self->{bbsobj}->board_list_last($self->{board}));
        return if $self->{_phash}[0][0]{$key};

        my $obj = $self->module('Article')->new(
                $self->{bbsobj},
                $self->{board},
                $self->{basepath},
                $key,
                "",
                $key,
            );

        $self->{_phash}[0][0]{$key} = $key;
        $self->{_phash}[0][$key] = $obj;
        return 1;
    }

    local $_;

    $self->{_phash}[0] = fields::phash(map {
        # return the thing
        ($_, $self->module('Article')->new(
                $self->{bbsobj},
                $self->{board},
                $self->{basepath},
                $_,
                "",
                $_,
        ));
    } (1..int($self->{bbsobj}->board_list_last($self->{board}))));

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $body = << ".";
作者: $value->{header}{From} 看板: $value->{header}{Board}
標題: $value->{header}{Subject}
時間: $value->{header}{Date}

$value->{body}
.

    use Mail::Address;
    my $author = (Mail::Address->parse($value->{header}{From}))[0]->user;

    if ($author ne $self->{bbsobj}{var}{username}) {
        $author =~ s/\..*//;
        $author .= '.';
    }
    else {
        $author = ''; # no need to change author
    }

    $self->{bbsobj}->article_post_raw(
        $self->{board},
	    $value->{header}{Subject},
	    $body,
	    $author,
	);
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});
}

1;
