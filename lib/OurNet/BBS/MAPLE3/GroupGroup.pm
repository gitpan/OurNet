package OurNet::BBS::MAPLE3::GroupGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot mtime _cache/;
use File::stat;

sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/gem/@/";

    if ($key) {
        $self->{_cache}{$key} = $self->module('Group')->new(
            $self->{bbsroot}, $key,
        );
        return;
    }

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};
    $self->{mtime} = stat($file)->mtime;

    opendir DIR, $file or die "can't read group file $file: $!";
    %{$self->{_cache}} = map {
        s/^\@//;
        ($_, $self->module('Group')->new($self->{bbsroot}, $_));
    } grep {
        my $st = stat("$self->{bbsroot}/gem/@/$_");
        /^\@/ and $st and $st->size % 256 == 0;
    } readdir(DIR);

    # clkao says its unneccessary
    # foreach my $key (keys %{$self->{_cache}}) {
    #     delete $self->{_cache}{$key} unless $self->{_cache}{$key};
    # }

    closedir DIR;
}
