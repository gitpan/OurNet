package LWP::Protocol::bbs;
require 5.005;

$LWP::Protocol::bbs::VERSION = '0.1';

use strict;

use OurNet::BBS;
use OurNet::BBS::PlClient;
use HTTP::Status;
use HTTP::Response;
use LWP::Debug;

use base qw/LWP::Protocol/;

=head1 NAME

LWP::Protocol::bbs - BBS/RPC support for LWP

=head1 SYNOPSIS

    # start daemon
    % bbscomd MAPLE2 /srv/bbs

    # fetch some property
    % lwp-download bbs://localhost/boards/sysop/articles/1/body

=head1 DESCRIPTION

    This is an attempt to combine raw BBS fetch with LWP protocol,
    intended to be used as the bridge to foreign renderes.

    It's still in early alpha stage, and the interface remains
    undecided as of now.

=cut

sub request {
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    LWP::Debug::trace('()');

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
	return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'http:' URLs";
    }

    my $url = ${$request->url};
    die "Protocol spec not good" unless $url =~ s|^\w+://([^/]+)/||;
    my ($host, $port) = split(/:/, $1);

    # connect to remote site
    my $BBS = OurNet::BBS::PlClient->new($host, $port || 7978);
    my $obj = $BBS;

    foreach my $chunk (split('/', $url)) {
        next if $chunk eq '';
        my $ego = tied(%{tied(%{$obj})->{_hash}});
        
        if (index($ego->{remote_ref}, '=ARRAY(') > -1 and $chunk =~ /^\d+$/) {
            $obj = $obj->[$chunk];
        }
        else {
            $obj = $obj->{$chunk};
        }
        print "obj: $obj\n";
    }
   
    if (ref($obj)) {
        # XXX need some Dumper action here instead of returning a ref
    }

    my $response = new HTTP::Response &HTTP::Status::RC_OK;
    my $flag; # only fetchs for the first time

    $response->header('Content-Type' => "text/plain");
    $response->header('Content-Length' => length($obj));
    $response->request($request);
    $response = $self->collect($arg, $response, sub { 
        $flag++ ? \"" : \$obj
    });
    return $response;
}

1;

__END__
=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

=cut
