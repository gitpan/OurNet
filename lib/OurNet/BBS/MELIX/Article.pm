package OurNet::BBS::MELIX::Article;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE3::Article/;
use fields qw/_cache/;

BEGIN {__PACKAGE__->initvars()};

sub STORE {
    my ($self, $key, $value) = @_;
    $self->refresh_meta($key);

    if ($key eq 'body') {
        my $file = join('/', $self->basedir, substr($self->{name}, -1), $self->{name});
        unless (-s $file or substr($value, 0, 6) eq '§@ªÌ: ') {
	    my $hdr = $self->{_cache}{header};
            $value = join('', map {"$_: $hdr->{$_}\n"} keys %{$hdr})."\n$value";
        }
        open _, ">$file" or die "cannot open $file";
        print _ $value;
        close _;
        $self->{btime} = stat($file)->mtime;
        $self->{_cache}{$key} = $value;
    }
    else {
        if ($key eq 'title' and
            substr($self->{basepath}, 0, 4) eq 'man/' and
            substr($value, 0, 3) ne '¡º ') {
            $value = "¡º $value";
        }

        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir, $self->{hdrfile});
        
	open DIR, "+<$file" or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek DIR, $packsize * $self->{recno}, 0;
        print DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close DIR;
        $self->{mtime} = stat($file)->mtime;
    }
}

1;
