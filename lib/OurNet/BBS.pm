package OurNet::BBS;
require 5.005;

$OurNet::BBS::VERSION = "0.1";

use strict;
use base qw/OurNet::BBS::Base/;
use fields qw/backend bbsroot brdshmkey maxboard sessionshmkey maxsession
              usershmkey maxuser chatport _cache/;
use OurNet::BBS::Utils;

=head1 NAME

OurNet::BBS - Component Object Model for BBS systems

=head1 SYNOPSIS

    use strict;
    use OurNet::BBS;
    
    my $backend = 'CVIC'; # same as 'OurNet::BBS::CVIC'
    my $bbsroot = '/srv/bbs/cvic';
    my $board   = 'sysop';
    my $BBS     = OurNet::BBS->new($backend, $bbsroot);
    my $brd     = $BBS->{boards}{$board};
    my $mtime;
    
    printf (
        "This BBS has %d boards, %d groups.\n",
        scalar keys(%{$BBS->{boards}}),
        scalar keys(%{$BBS->{groups}}),
    );
    
    eval { $mtime = $brd->{articles}->mtime };
    die "Error: cannot read board $board -- $@\n" if $@;
    
    printf (
        "The $board board has %d articles, %d toplevel archive entries.\n",
        $#{$brd->{articles}}, $#{$brd->{archives}},
    );
    
    # A simple Sysop board article monitor
    print "Watching for new articles...\n";
    
    while (1) {
        print "=== wait here ($mtime) ===\n";
        sleep 5 until ($brd->{articles}->refresh);
    
        foreach my $article (@{$brd->{articles}}[1..$#{$brd->{articles}}]) {
        	print "Found article: $article->{title}\n" if $article->btime > $mtime;
        }
    
        $mtime = $brd->{articles}->mtime;
    }

=head1 DESCRIPTION

OurNet::BBS implements a flexible object model for different BBS backends.

More detailed document is expected to appear soon.

=cut

sub refresh_boards {
    my ($self, $key) = @_;

    return $self->fillin($key, 'BoardGroup', $self->{bbsroot},
			 $self->{brdshmkey}, $self->{maxboard});

}

sub refresh_groups {
    my ($self, $key) = @_;

    return $self->fillin($key, 'GroupGroup', $self->{bbsroot});
}

sub refresh_sessions {
    my ($self, $key) = @_;

    return $self->fillin($key, 'SessionGroup', $self->{bbsroot},
			 $self->{sessionshmkey}, $self->{maxsession},
                         $self->{chatport});
}

sub refresh_users {
    my ($self, $key) = @_;

    return $self->fillin($key, 'UserGroup', $self->{bbsroot},
			 $self->{usershmkey}, $self->{maxuser});
}

sub refresh_meta {
    # do nothing -- as of now
}

sub fillin {
    my ($self, $key, $class) = splice(@_, 0, 3);
    return if defined($self->{_cache}{$key});

    my $prefix = (index($self->{backend}, '::') > -1 ? '' : (ref($self).'::'));
    my $module = "$prefix$self->{backend}/$class.pm";
    $module =~ s|::|/|g;
    require $module;

    $self->{_cache}{$key} = "$prefix$self->{backend}::$class"->new(@_);
    
    return 1;
}

1;

__END__

=head1 AUTHORS

Chia-Liang Kao E<lt>clkao@clkao.org>
Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>,
                  Chia-Liang Kao E<lt>clkao@clkao.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

=cut
