package OurNet::BBS::MAPLE3::Board;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE2::Board/;
use fields qw/_cache/;
use subs qw/post_new_board refresh_articles refresh_archives shmtouch/;

BEGIN { __PACKAGE__->initvars() };

sub post_new_board {
    my $self = shift;
    foreach my $dir (
        "$self->{bbsroot}/brd/$self->{board}/",
        "$self->{bbsroot}/gem/brd/$self->{board}/",
    ) {
        mkdir $dir;

        foreach my $subdir (0..9, 'A'..'V', '@') {
            mkdir "$dir$subdir";
        }
    }
}

sub refresh_articles {
    my $self = shift;

    return $self->{_cache}{articles} ||= $self->module('ArticleGroup')->new
      ({
	basepath => "$self->{bbsroot}/brd",
	board => $self->{board},
	idxfile => '.DIR',
       });
}

sub shmtouch {
    my $self = shift;
# XXX this doesn't work, why?
    print "number => $self->{shm}{number}\n";
    print "uptime => $self->{shm}{uptime}\n";

    $self->{shm}{uptime} = 0;
}

sub refresh_archives {
    my $self = shift;

    return $self->{_cache}{archives} ||= $self->module('ArticleGroup')->new
      ({
	basepath => "$self->{bbsroot}/gem/brd",
	board => $self->{board},
	idxfile => '.DIR',
       });
}

1;
