package OurNet::BBS::MAPLE2::User;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot id recno _cache/;
use File::stat;

sub refresh_meta {
    my $self = shift;
    my $key  = shift;

    $self->{_cache}{uid} ||= $self->{recno} - 1;
    $self->{_cache}{name} ||= $self->{id};
    return if exists $self->{_cache}{$key};
    require OurNet::BBS::ScalarFile;
    tie $self->{_cache}{$key}, 'OurNet::BBS::ScalarFile',
        "$self->{bbsroot}/home/$self->{id}/$key";

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    $self->{_cache}{mailbox} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot},
        $self->{id},
        'home',
    );
}


sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;
}

1;

