package OurNet::BBS::MAPLE3::ArticleGroup;
$VERSION = "0.1";

# hdrfile for the upper level hdr file holding metadata of this level
# idxfile for hdr of the deeper level that this articlegroup is holding.
use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/basepath board name dir hdrfile idxfile recno mtime btime _cache _phash/;
use File::stat;

use constant GEM_FOLDER		=> 0x00010000;
use constant GEM_BOARD		=> 0x00020000;
use constant GEM_GOPHER		=> 0x00040000;
use constant GEM_HTTP		=> 0x00080000;
use constant GEM_EXTEND		=> 0x80000000;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'LLLZ32Z80Z50Z9Z73',
        '$packsize'   => 256,
        '@packlist'   => [qw/time xmode xid id author nick date title/],
    );
}

sub basedir {
    my $self = shift;

#print "$self->{basepath}, $self->{board}\n";

    return join('/', $self->{basepath}, $self->{board});
}

sub stamp {
    my $chrono = shift;
    my $str = '';
    for (1..7) {
	$str = ((0..9,'A'..'V')[$chrono & 31]) . $str;
	$chrono >>= 5;
    }
    return 'A'.$str;
}

sub new_id {
    my $self = shift;
    my ($id, $file);

    while ($id = stamp(time())) {
        $file = join('/', $self->basedir(), substr($id, -1), $id);
        last unless -e $file;
        sleep 1;
    }

    return $id;
}

sub refresh_id {
    my ($self, $key) = @_;
    $self->{name} ||= $self->new_id();
    my $file = join('/', $self->basedir(), $self->{hdrfile});
    return if $self->{btime} and stat($file)->mtime == $self->{btime}
              and defined $self->{recno};

    $self->{btime} = stat($file)->mtime;

    local $/ = \$packsize;
    open DIR, "$file" or die "can't read DIR file for $self->{board}: $!";
    if (defined $self->{recno}) {
        seek DIR, $packsize * $self->{recno}, 0;
        @{$self->{_cache}}{@packlist} = unpack($packstring, <DIR>);
        if ($self->{_cache}{id} ne $self->{name}) {
            undef $self->{recno};
            seek DIR, 0, 0;
        }
    }

    unless (defined $self->{recno}) {
        $self->{recno} = 0;
        while (my $data = <DIR>) {
            @{$self->{_cache}}{@packlist} = unpack($packstring, $data);
            # print "$self->{_cache}{id} versus $self->{name}\n";
            last if ($self->{_cache}{id} eq $self->{name});
            $self->{recno}++;
        }
        if ($self->{_cache}{id} ne $self->{name}) {
            $self->{_cache}{id} = $self->{name};
	    $self->{_cache}{xmode} = GEM_FOLDER;
            $self->{_cache}{author}   ||= 'guest.';
            $self->{_cache}{date}     = sprintf("%02d/%02d/%02d", substr((localtime)[5]+1900, -2), (localtime)[4] + 1, (localtime)[3]);
            $self->{_cache}{title}    = '¡» (untitled)';
            $self->{_cache}{filemode} = 0;
            open DIR, "+>>$file" or die "can't write DIR file for $self->{board}: $!";
            print DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close DIR;

	    open DIR, ">".join('/', $self->basedir(), substr($self->{name}, -1), $self->{name});
            close DIR;

            # print "Recno: ".$self->{recno}."\n";
        }
    }

    return 1;
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

#    local $^W = 0; # turn off warnings
    my $file = join('/', $self->basedir(), $self->{idxfile});
    my $name;

    if ($key and index(' '.join(' ',@packlist).' ', " $key ") > -1) {
        goto &refresh_id;
    }
    elsif (!defined($key) and $self->{dir}) {
        $self->refresh_id;
    }
    if ($key and !($key =~ /^\d+$/)) {
        # hash key -- no recaching needed
        return if $self->{_phash}[0][0]{$key};
        my $obj = $self->module(substr($key, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{basepath},
                $self->{board},
                $key,
                "$self->{dir}/$self->{name}",
		'.DIR',
            );

        $self->{_phash}[0][0]{$key} = $obj->recno+1;
        $self->{_phash}[0][$obj->recno+1] = $obj;

        return 1;
    }

    open DIR, $file or (warn "can't read DIR file for $file: $!", return);

    if ($key) {
        # out-of-bound check
        die 'no such article' if $key < 1 || $key > int(stat($file)->size / $packsize);

	my (%param, %foo);
        seek DIR, $packsize * ($key-1), 0;
	local $/ = \$packsize;
	@foo{@packlist} = unpack($packstring, <DIR>);
        $name = $foo{id};
#        return if $self->{_phash}[0][0]{$name} == $key;

	$param{idxfile}	= substr($foo{id},-1)."/$foo{id}"
	  if $foo{xmode} & GEM_FOLDER;
        my $obj = $self->module(($foo{xmode} & GEM_FOLDER)
            ? 'ArticleGroup' : 'Article')->new
	      ({
		board	=> $self->{board},
		basepath=> $self->{basepath},
		name	=> $name,
		hdrfile	=> $self->{idxfile},
		recno	=> $key-1,
		%param
	       });
        $self->{_phash}[0][0]{$name} = $key;
        $self->{_phash}[0][$key] = $obj;

        close DIR;
        return 1;
    }

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};
    $self->{mtime} = stat($file)->mtime;
    $self->{_phash}[0] = fields::phash(map {
	my (%param, %foo);
        seek DIR, $packsize * ($_), 0;
	local $/ = \$packsize;
	@foo{@packlist} = unpack($packstring, <DIR>);
        $name = $foo{id};
        # return the thing
	$param{idxfile}	= substr($foo{id},-1)."/$foo{id}"
	  if $foo{xmode} & GEM_FOLDER;

        ($name, $self->module(($foo{xmode} & GEM_FOLDER)
            ? 'ArticleGroup' : 'Article')->new
	 ({
	  board		=> $self->{board},
	  basepath	=> $self->{basepath},
	  name		=> $name,
	  hdrfile	=> $self->{idxfile},
	  recno		=> $_,
	  %param,
	  })
        );
    } (0..int(stat($file)->size / $packsize)-1));

    close DIR;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    local $^W = 0; # turn off warnings

    if ($key and index(' '.join(' ', @packlist).' ', " $key ") > -1) {
        $self->refresh($key);
        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir(), '.DIR');

        open DIR, "+<$file" or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek DIR, $packsize * $self->{recno}, 0;
        print DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close DIR;
        $self->{mtime} = stat($file)->mtime;
    }
    else {
        use Carp;
        confess "STORE: attempt to store non-hash value ($value) into $key: ".ref($self)
            unless UNIVERSAL::isa($value, 'HASH');

        my $obj;

        if ($key > 0 and exists $self->{_phash}[0][$key]) {
            $obj = $self->{_phash}[0][$key];
        }
        else {
            my $class  = (UNIVERSAL::isa($value, "UNIVERSAL"))
                ? ref($value) : $self->module('Article');

            my $module = "$class.pm";
            $module =~ s|::|/|g;
            require $module;
            $obj = $class->new
	      ({
                basepath=> $self->{basepath},
                board	=> $self->{board},
                name	=> "$self->{name}",
		hdrfile	=> $self->{idxfile},
                recno	=> int($key) ? $key - 1 : undef,
	       });
        }

        while (my ($k, $v) = each %{$value}) {
	    $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
        };

        $obj->{body} = $value->{body} || "\n";
        $self->refresh($key);
    }
}

sub EXISTS {
    my ($self, $key) = @_;
    return 1 if exists ($self->{_cache}{$key});

    my $file = join('/', $self->basedir(), $self->{name}, '.DIR');
    return 0 if $self->{mtime} and stat($file)->mtime == $self->{mtime};

    open DIR, $file or die "can't read DIR file $file: $!";

    my $board;
    foreach (0..int(stat($file)->size / $packsize)-1) {
        seek DIR, $packsize * $_, 0;
        read DIR, $board, 44;
        return 1 if unpack('x12Z32', $board) eq $key;
    }

    close DIR;
    return 0;
}

1;
