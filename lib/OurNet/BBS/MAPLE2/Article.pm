package OurNet::BBS::MAPLE2::Article;

$OurNet::BBS::MAPLE2::Article::VERSION = "0.1";

use File::stat;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot board basepath name dir recno mtime btime _cache/;
use vars qw/$backend $packstring $packsize @packlist/;

$backend    = 'MAPLE2';
$packstring = ${"OurNet::BBS::${backend}::ArticleGroup::packstring"};
$packsize   = ${"OurNet::BBS::${backend}::ArticleGroup::packsize"};
@packlist   = @{"OurNet::BBS::${backend}::ArticleGroup::packlist"};

sub basedir {
    my $self = shift;
    return join('/', $self->{bbsroot}, $self->{basepath},
                     $self->{board}, $self->{dir});
}

sub new_id {
    my $self = shift;
    my ($id, $file);
    
    $file = $self->basedir();
    
    unless (-e "$file/.DIR") {
        open _, ">$file/.DIR" or die "cannot create $file/.DIR";
	close _;
    }

    while ($id = "M.".(scalar time).".A") {
	last unless -e "$file/$id";
	sleep 1;
    }
    
    open _, ">$file/$id" or die "cannot open $file/$id";
    close _;
    
    return $id;
}

sub refresh_body {
    my $self = shift;

    $self->{name} ||= $self->new_id();

    my $file = join('/', $self->basedir, $self->{name});

    return if $self->{btime} and stat($file)->mtime == $self->{btime}
                             and defined $self->{_cache}{body};

    $self->{btime} = stat($file)->mtime;
    $self->{_cache}{date} ||= sprintf("%2d/%02d", (localtime($self->{btime}))[4] + 1, (localtime($self->{btime}))[3]);

    local $/;
    open _, $file or die "can't open DIR file for $self->{board}";
    $self->{_cache}{body} = <_>;

    return 1;
}

sub refresh_meta {
    my $self = shift;

    $self->{name} ||= $self->new_id();

    my $file = join('/', $self->basedir, $self->{name});
    return unless -e $file;
    $self->{btime} = stat($file)->mtime;

    $file = join('/', $self->basedir, '.DIR');

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};
    $self->{mtime} = stat($file)->mtime;
    
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
            $self->{_cache}{author}   ||= 'guest.';
            $self->{_cache}{nick}     ||= '天外來客';
            $self->{_cache}{date}     = sprintf("%2d/%02d", (localtime)[4] + 1, (localtime)[3]);
            $self->{_cache}{title}    = (substr($self->{basepath}, 0, 4) eq 'man/')
                ? '◇ (untitled)' : '(untitled)';
            $self->{_cache}{filemode} = 0;
            open DIR, "+>>$file" or die "can't write DIR file for $self->{board}: $!";
            print DIR pack($packstring, @{$self->{_cache}}{@packlist});
            close DIR;
            # print "Recno: ".$self->{recno}."\n";
        }
    }

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);

    if ($key eq 'body') {
        my $file = join('/', $self->basedir, $self->{name});
        unless (-s $file or substr($value, 0, 6) eq '作者: ') {
            $value =
            "作者: $self->{_cache}{author} ($self->{_cache}{nick}) ".
            "看板: $self->{board} \n標題: ".substr($self->{_cache}{title}, 0, 60).
            "\n時間: ".($self->{_cache}{datetime} || scalar localtime)."\n\n".$value;
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
            substr($value, 0, 3) ne '◇ ') {
            $value = "◇ $value";
        }

        $self->{_cache}{$key} = $value;

        my $file = join('/', $self->basedir, '.DIR');
        
	open DIR, "+<$file" or die "cannot open $file for writing";
        # print "seeeking to ".($packsize * $self->{recno});
        seek DIR, $packsize * $self->{recno}, 0;
        print DIR pack($packstring, @{$self->{_cache}}{@packlist});
        close DIR;
        $self->{mtime} = stat($file)->mtime;
    }
}

sub remove {
    my $self = shift;
    my $file = join('/', $self->basedir, '.DIR');

    open DIR, $file or die "cannot open $file for reading";
    # print "seeeking to ".($packsize * $self->{recno});

    my $buf = '';
    if ($self->{recno}) {
        # before...
        seek DIR, 0, 0;
        read(DIR, $buf, $packsize * $self->{recno});
    }
    if ($self->{recno} < (stat($file)->size / $packsize) - 1) {
        seek DIR, $packsize * ($self->{recno}+1), 0;
        read(DIR, $buf, $packsize * (stat($file)->size - (($self->{recno}+1) * $packsize)));
    }

    close DIR;

    open DIR, ">$file" or die "cannot open $file for writing";
    print DIR $buf;
    close DIR;

    return unlink join('/', $self->basedir, $self->{name});
}

1;

