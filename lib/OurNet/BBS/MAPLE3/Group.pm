package OurNet::BBS::MAPLE3::Group;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot group mtime _cache/;
use OurNet::BBS::MAPLE3::Board;
use File::stat;

use constant GEM_FOLDER         => 0x00010000;
use constant GEM_BOARD          => 0x00020000;
use constant GEM_GOPHER         => 0x00040000;
use constant GEM_HTTP           => 0x00080000;
use constant GEM_EXTEND         => 0x80000000;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'LLLZ32Z80Z50Z9Z73',
        '$packsize'   => 256,
        '@packlist'   => [qw/time xmode xid id author nick date title/],
    );
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/gem/@/@".$self->{group};
    my $board;
    return unless $self->{group};
    local *GROUP;

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};

    open (GROUP, $file) or open (GROUP, "+>>$file")
        or die("Cannot read group file $file: $!");

    my $st = stat($file);
    $self->{mtime} = $st->mtime;

    return if $st->size % $packsize;
    local $/ = \$packsize;
    my %foo;
    my $buf;
    while ($buf = <GROUP> and @foo{@packlist} = unpack($packstring, $buf)) {
	$foo{id} =~ s/^@//;
	if ($foo{xmode} & GEM_BOARD) {
            $self->{_cache}{$foo{id}} = OurNet::BBS::MAPLE3::Board->new(
                $self->{bbsroot}, $foo{id}
            );

	}
	elsif ($foo{xmode} & GEM_FOLDER) {
            $self->{_cache}{$foo{id}} = OurNet::BBS::MAPLE3::Group->new(
                $self->{bbsroot}, $foo{id});
	}
    }
    close GROUP;
}
