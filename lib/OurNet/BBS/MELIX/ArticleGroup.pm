package OurNet::BBS::MELIX::ArticleGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::MAPLE3::ArticleGroup/;
use fields qw/_cache _phash/;
use subs qw/STORE/;
BEGIN {__PACKAGE__->initvars()};

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
                basepath => $self->{basepath},
                board    => $self->{board},
                name     => "$self->{name}",
                hdrfile  => $self->{idxfile},
                recno    => int($key) ? $key - 1 : undef,
               });
        }

        use Mail::Address;
        use Date::Parse;
        use Date::Format;

        # use Data::Dumper;
        # print Dumper($value);

        if ($value->{header}) {
            if (my $adr = (Mail::Address->parse($value->{header}{From}))[0]) {
                $value->{author} = $adr->address;
                $value->{nick} = $adr->comment;
            }
            
            $value->{date} = time2str('%y/%m/%d', str2time($value->{header}{Date}));
            $value->{title} = $value->{header}{Subject};
        }
        else {
            # traditional style
            $value->{header} = {
                'From' => "$value->{author} ($value->{nick})",
                'Date' => scalar localtime,
                'Subject' => $value->{title},
                'Board' => $self->board,
            }
        }

        while (my ($k, $v) = each %{$value}) {
            $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
        };

        $obj->{body} = $value->{body} if ($value->{body});
        $self->refresh($key);
    }
}

1;
