package OurNet::BBS::PlServer;

use strict;
use RPC::PlServer;
use base qw/RPC::PlServer/;
use vars qw/$ROOT/;

$OurNet::BBS::PlServer::VERSION = '0.1';

sub daemonize {
    my $self = shift;
    $ROOT = shift;

    # Server options below can be overwritten in the config file or
    # on the command line.
    my $server = __PACKAGE__->new({
        'pidfile'    => 'none',
        'facility'   => 'daemon', # Default
        'methods'    => {
            'OurNet::BBS::PlServer' => {
                'NewHandle' => 1,
                'CallMethod' => 1,
                'DestroyHandle' => 1,
                'spawn' => 1,
                'invoke' => 1,
                'rootref' => 1,
            },
        },    
        'localport'  => shift || 2000,
        'mode'       => 'fork',   # Recommended for Unix
    });
    $server->Bind();
}

sub spawn {
    return (bless(\$ROOT, $_[0]));
}

sub rootref {
    return ref($ROOT);
}

sub invoke {
    my $self = shift;
    my $obj = $$self;

    while (my $op = shift) {
        my $param = shift;
        my $arg = shift(@{$param});
        
        # print "traversing: $obj -> $op $arg\n";
        if ($op =~ m/^OBJECT\.(.+)/) {
            @_ = $obj->$1($arg, @{$param});
            return unless $#_ == 0;
            $obj = $_[0];
        } elsif ($op eq 'HASH.FETCH') {
            $obj = $obj->{$arg};
	} elsif ($op eq 'HASH.DESTROY') {
            return;
        } elsif ($op eq 'ARRAY.DESTROY') {
            return;
        } elsif ($op eq 'HASH.FETCHARRAY') {
            $obj = $obj->[$arg];
        } elsif ($op eq 'ARRAY.FETCH') {
            $obj = $obj->[$arg];
        } elsif ($op eq 'ARRAY.FETCHSIZE') {
            $obj = $#{$obj};
        } elsif ($op eq 'ARRAY.DEREFERENCE') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return @{$obj};
        } elsif ($op eq 'HASH.DEREFERENCE') {
            # return $arg ? @{$obj}{ref($arg) ? @{$arg} : $arg} : %{$obj};
            return %{$obj};
        } elsif ($op eq 'ARRAY.STORE') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return ($obj->[$arg] = $param->[0]);
        } elsif ($op eq 'HASH.STORE') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
	    return ($obj->{$arg} = $param->[0]);
        } elsif ($op eq 'ARRAY.DELETE') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return (delete $obj->[$arg]);
        } elsif ($op eq 'HASH.DELETE') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return (delete $obj->{$arg});
        } elsif ($op eq 'ARRAY.PUSH') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return (push @{$obj->{$arg}}, @{$param});
        } elsif ($op eq 'ARRAY.POP') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            $obj = pop(@{$obj->{$arg}});
        } elsif ($op eq 'ARRAY.SHIFT') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            $obj = shift(@{$obj->{$arg}});
        } elsif ($op eq 'HASH.EXISTS') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return exists ($obj->{$arg});
        } elsif ($op eq 'ARRAY.EXISTS') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return exists ($obj->[$arg]);
        } elsif ($op eq 'ARRAY.UNSHIFT') {
            # return $arg ? @{$obj}[ref($arg) ? @{$arg} : $arg] : @{$obj};
            return (unshift @{$obj->{$arg}}, @{$param});
        } else {
            warn "Unknown OP: $op\n";
        }
    }

    # print "return: ", (ref($obj) ? ('OBJECT.SPAWN', scalar $obj) : $obj), "\n";
    return (ref($obj)) ? ('OBJECT.SPAWN', scalar $obj) : $obj;
}


