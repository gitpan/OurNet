package OurNet::BBS::MAPLE3::ArticleGroup;
$VERSION = "0.1";

use strict;
#use base qw/OurNet::BBS::MAPLE2::ArticleGroup/;
#use fields qw/_cache _phash/;
use File::stat;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot board basepath name dir recno mtime btime _cache _phash/;
use vars qw/$packstring $packsize @packlist/;

$packstring = 'LLLZ32Z80Z50Z9Z73';
$packsize   = 256;
@packlist   = qw/time xmode xid id author nick date title/;

1;

sub basedir {
    my $self = shift;
    return join('/', $self->{bbsroot}, $self->{basepath},
                     $self->{board}, $self->{dir});
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
die "$self: refresh $key\n";
    $self->{name} ||= $self->new_id();

    my $file = join('/', $self->basedir(), '.DIR');

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
            # die "not supposed to be here: $self->{_cache}{id}, $self->{name}";
            $self->{_cache}{id} = $self->{name};
            $self->{_cache}{author}   ||= 'guest.';
            $self->{_cache}{date}     = sprintf("%2d/%02d", (localtime)[4] + 1, (localtime)[3]);
            $self->{_cache}{title}    = '¡» (untitled)';
            $self->{_cache}{filemode} = 0;
            open DIR, "+>>$file" or die "can't write DIR file for $self->{board}: $!";
            print DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close DIR;

            mkdir join('/', $self->basedir(), $self->{name});
            open DIR, ">".join('/', $self->basedir(), '.DIR');
            close DIR;

            # print "Recno: ".$self->{recno}."\n";
        }
    }

    return 1;
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    local $^W = 0; # turn off warnings

    my $file = join('/', $self->basedir(), $self->{name}, '.DIR');
    my $name;

    if ($key and index(' '.join(' ',@packlist).' ', " $key ") > -1) {
        goto &refresh_id;
    }
    elsif (!defined($key) and $self->{dir}) {
        $self->refresh_id;
    }
    if ($key and $key ne int($key)) {
        # hash key -- no recaching needed
        return if $self->{_phash}[0][0]{$key};

        my $obj = $self->module(substr($key, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $key,
                "$self->{dir}/$self->{name}",
            );

        $self->{_phash}[0][0]{$key} = $obj->recno+1;
        $self->{_phash}[0][$obj->recno+1] = $obj;

        return 1;
    }

    open DIR, $file or (warn "can't read DIR file for $file: $!", return);

    if ($key) {
        # out-of-bound check
        return if $key < 1 or $key > int(stat($file)->size / $packsize);

        seek DIR, $packsize * ($key-1), 0;
        read DIR, $name, 44;
        $name = unpack('x12Z32', $name);
        # print "$name unpacked\n";
        return if $self->{_phash}[0][0]{$name} == $key;

        my $obj = $self->module(substr($name, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $name,
                "$self->{dir}/$self->{name}",
                $key-1,
            );

        $self->{_phash}[0][0]{$name} = $key;
        $self->{_phash}[0][$key] = $obj;

        close DIR;
        return 1;
    }

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};
    $self->{mtime} = stat($file)->mtime;
    $self->{_phash}[0] = fields::phash(map {
        seek DIR, $packsize * $_, 0;
        read DIR, $name, 44;
        $name = unpack('x12Z32', $name);
        # return the thing
        ($name, $self->module(substr($name, 0, 2) eq 'D.'
            ? 'ArticleGroup' : 'Article')->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                $name,
                "$self->{dir}/$self->{name}",
                $_,
        ));
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

            $obj = $class->new(
                $self->{bbsroot},
                $self->{board},
                $self->{basepath},
                undef,
                "$self->{dir}/$self->{name}",
                int($key) ? $key - 1 : undef,
            );
        }

        while (my ($k, $v) = each %{$value}) {
	    $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
        };

        $obj->{body} = $value->{body} if ($value->{body});
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
