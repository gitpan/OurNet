package OurNet::BBS::MAPLE3::UserGroup;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot maxuser _cache _phash/;
use File::stat;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $arrayfetch) = @_;
    my $name;

    if ($key) {
        if (length($key) and $arrayfetch) {
            # array fetch
            local *DIR;
            open DIR, "$self->{bbsroot}/.USR";
            seek DIR, ($key - 1) * 16 + 4, 0;
            read DIR, $name, 12;
            $name = unpack('Z14', $name);
            close DIR;
            return if $self->{_phash}[0][0]{$name} == $key;
        }
        elsif ($key) {
            # key fetch
            $name = $key;
            return if $self->{_phash}[0][0]{$key};
            $key = 0;
        }
    }
    else {
        # $key = $self->{maxuser}++; 
    }

    my $obj = $self->module('User')->new(
        $self->{bbsroot},
        $name,
        $key, # XXX -1?
    );

    $key ||= $obj->{userno};

    $self->{_phash}[0][0]{$name} = $key;
    $self->{_phash}[0][$key] = $obj;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;

    die "STORE: attempt to store non-hash value ($value) into $key: ".ref($self)
        unless UNIVERSAL::isa($value, 'HASH');
    die "Modification not supported" if $key;

    my $obj;

    my $class  = (UNIVERSAL::isa($value, "UNIVERSAL"))
            ? ref($value) : $self->module('User');

    my $module = "$class.pm";
    $module =~ s|::|/|g;
    require $module;
    $obj = $class->new({
        basepath=> $self->{basepath},
        board	=> $self->{board},
        name	=> "$self->{name}",
        hdrfile	=> $self->{idxfile},
        recno	=> int($key) ? $key - 1 : undef,
    });

    while (my ($k, $v) = each %{$value}) {
        $obj->{$k} = $v unless $k eq 'body' or $k eq 'id';
    };

    $obj->{body} = $value->{body} if ($value->{body});
    $self->refresh($key);
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists ($self->{_cache}{$key}) or
           -d "$self->{bbsroot}/usr/".
              lc(substr($self->{id}, 0, 1))."/$self->{id}";

}

1;


