package OurNet::BBS::MAPLE3::User;
$VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot id recno _cache/;
use File::stat;

BEGIN {
    __PACKAGE__->initvars(
        '$packstring' => 'iZ13Z14CZ20Z24IiiILLLLZ32iLZ60Z60Z60Z60Z120L',
        '$packsize'   => 512,
        '@packlist'   => [
            qw/userno userid passwd signature realname username userlevel 
               numlogins numposts ufo firstlogin lastlogin staytime tcheck 
               lasthost numemail tvalid email address justify vmail ident 
               vtime/
        ],
    );
}

sub refresh_meta {
    my $self = shift;
    my $key  = shift;

    $self->{_cache}{uid} ||= $self->{recno} - 1;
    $self->{_cache}{name} ||= $self->{id};
    return if exists $self->{_cache}{$key};

    my $dir = "$self->{bbsroot}/usr/".
              lc(substr($self->{id}, 0, 1))."/$self->{id}";
    local *USR;
    local $/;

    unless (-d $dir) {
        mkdir $dir or die "cannot mkdir $dir\n";
        open USR, ">$self->{bbsroot}/usr/".
                  lc(substr($self->{id}, 0, 1))."/$self->{id}".
                  "/.ACCT";
        $self->{_cache}{userno} = stat("$self->{bbsroot}/.USR")->size / 16;
        $self->{_cache}{userid} = $self->{id};
        $self->{_cache}{userlevel} = 15;
        $self->{_cache}{ufo} = 15;
        print USR pack($packstring, @{$self->{_cache}}{@packlist});
        close USR;
        open USR, ">>$self->{bbsroot}/.USR" or die "too random";
        print USR pack("LZ12", time(), $self->{id});
        close USR;
    }

    open USR, 
        "$self->{bbsroot}/usr/".
        lc(substr($self->{id}, 0, 1))."/$self->{id}".
        "/.ACCT";

    @{$self->{_cache}}{@packlist} = unpack($packstring, <USR>);
    # print "$_ => $self->{_cache}{$_}\n" foreach @packlist;
    close USR;

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    $self->{_cache}{mailbox} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot},
        'usr/'.lc(substr($self->{id}, 0, 1))."/$self->{id}".
        '',
        '',
        '.DIR',
        '',
    );
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self->refresh_meta($key);
    $self->{_cache}{$key} = $value;

    local *USR;
    open USR, 
        ">$self->{bbsroot}/usr/".
        lc(substr($self->{id}, 0, 1))."/$self->{id}".
        "/.ACCT"; 

    print USR pack($packstring, @{$self->{_cache}}{@packlist});
    close USR;
}

1;

