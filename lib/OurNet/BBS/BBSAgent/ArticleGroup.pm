package OurNet::BBS::BBSAgent::ArticleGroup;

$OurNet::BBS::BBSAgent::ArticleGroup::VERSION = "0.1";

use File::stat;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsobj board basepath _cache _phash/;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    require OurNet::BBS::BBSAgent::Article;

    if ($key and $key ne int($key)) {
        # hash key -- no recaching needed
        die 'hash key not implemented (!)';
    }

    if ($key) {
        # out-of-bound check
        local $^W = 0; # usage of int() below is voluntary
        return if $key < 1 or $key > int($self->{bbsobj}->board_list_last($self->{board}));
        return if $self->{_phash}[0][0]{$key};

        my $obj = OurNet::BBS::BBSAgent::Article->new(
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
        ($_, OurNet::BBS::BBSAgent::Article->new(
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
    print "attempted STORE: @_\n";
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});
}

1;
