package OurNet::BBS::CVIC::GroupGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot mtime _cache/;
use File::stat;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/group";

    require OurNet::BBS::CVIC::Group;

    if ($key) {
        $self->{_cache}{$key} ||= OurNet::BBS::CVIC::Group->new(
            $self->{bbsroot}, $key
        );
        return;
    }

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};
    $self->{mtime} = stat($file)->mtime;

    opendir DIR, $file or die "can't read group file $file: $!";
    %{$self->{_cache}} = map {
        ($_, OurNet::BBS::CVIC::Group->new($self->{bbsroot}, $_));
    } grep {
        /^[^\.]/;
    } readdir(DIR);
    closedir DIR;
}

sub STORE {
    my ($self, $key) = @_;

    $self->{_cache}{$key}->refresh();
}

sub EXISTS {
    my ($self, $key) = @_;

    return ((-e "$self->{bbsroot}/group/$key") ? 1 : 0);
}

1;
