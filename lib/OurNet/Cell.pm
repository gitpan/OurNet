package OurNet::Cell;
require 5.005;

$OurNet::Cell::VERSION = '1.0';

use strict;
use lib  qw/./;
use base qw/Exporter/;
use vars qw/@EXPORT %Cells $Debug/;

use IO::Select;
use IO::Socket::INET;

@EXPORT = qw/RunCells EndCells/;
%Cells  = qw//;
$Debug  = 0;

=head1 NAME

OurNet::Cell - An ONTP Cell.

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use OurNet::Cell;

    $OurNet::Cell::Debug = 1;

    my $daemon = OurNet::Cell->new('Daemon', 1);
    $daemon->daemonize();

    my $storage = OurNet::Cell->new('Storage', 1);

    $storage->hook('READ.DATA', sub {$_[0]->unicast($_[1], 'WRITE.DATA',
                                     $_[2], $_[0]->{'var'}{$_[1]}{$_[2]})});
    $storage->hook('WRITE.DATA', sub {$_[0]->{'var'}{$_[1]}{$_[2]} = $_[3]});
    $storage->contact(undef, 'localhost') or die;

    my $fetch = OurNet::Cell->new('Fetch', 1);
    $fetch->hook('WRITE.DATA', sub {print "\n$_[2] is $_[3].\n"});
    $fetch->contact(undef, 'localhost') or die;
    $remote = 'Storage';
    $fetch->contact($remote) or die;
    $fetch->unicast($remote, 'WRITE.DATA', 'Test', 'successful');
    RunCells 1;
    $fetch->unicast($remote, 'READ.DATA', 'Test');
    RunCells 1;

    EndCells;

=head1 DESCRIPTION

OurNet::Cell provides a cross-platform, socket-based approach to built
a real-time, state-based, free-form inter-net information-sharing
object-model. (please-insert random-hype right-here).

Prior to v0.1, this is highly experimental and unstable. Comments are
intentionally lacking -- you shouldn't bother with this module unless
you're 1) interested in concurrent mobile agent development, 2) a perl
guru, and 3) having a lot of time to spare.

=head1 TODO

=over 4

=item Cross-protocol support

UDP and HTTP support (at least) should be in contact() and daemonize().

=item Multicast

A multicast routing algorithm is under testing.

=item Findhook and Installhook

These two are crucial to its emulation to true 'cell' behaviour.

=item Spawn

Spawning-on-demanded is expected to function well, but need closer
inspection as to how it affects smart load-balancing.

=cut

# ---------------
# Variable Fields
# ---------------
use fields qw/id hook table socks localid peerid sel timeout var/;

# -----------------
# Package Constants
# -----------------
use constant BYPASS => $$ + rand();

# -----------------------------
# Subroutine new($id, $timeout)
# -----------------------------
sub new {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };

    $self->{'id'}      = shift;
    $self->{'timeout'} = shift;
    $self->{'sel'}     = IO::Select->new();

    $self->hook('META.TO' , \&_meta_to);
    $self->hook('META.ON' , \&_meta_on);
    $self->hook('META.OFF', \&_meta_off);

    $Cells{$self->{'id'}} = $self;

    return $self;
}

# ------------------------------------------
# Class method RunCells([$time, $assertion])
# ------------------------------------------
sub RunCells {
    my $self = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : undef;
    my $time = time;

    while (not ($_[1] and &{$_[1]})) {
        foreach my $cell (values(%Cells)) {
            $cell->check();
        }

        last if (defined $_[0] and (time - $time >= $_[0]));
    }
}

# -----------------------
# Class method EndCells()
# -----------------------
sub EndCells {
    my $self = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : undef;

    undef $Debug;

    foreach my $cell (values(%Cells)) {
        $cell->off();
    }

    undef %Cells;
}

# -----------------------------------------------
# Subroutine daemonize($self, [$port, $protocol])
# -----------------------------------------------
sub daemonize {
    my $self = shift;
    my $sock = IO::Socket::INET->new(Listen => 5, LocalPort => shift || 7978);

    $self->{'sel'}->add($sock);
    $self->{'socks'}{$sock->fileno} = $sock;

    return $self;
}

# Prints debug messages.
sub _debug {
    return unless $Debug;

    my $self   = shift;
    my $caller = (caller(1))[3];

    $caller =~ s|^.*::||;

    print "$self->{'id'}\t: ".join(', ', $caller, grep {defined $_} @_)."\n";
}

# The default call back function for META.ON.
sub _meta_on {
    my ($self, $remote, $arg) = @_;
    $self->_debug($remote, $arg);

    if ($self->{'peerid'}{$remote} ne $arg) {
        while (my ($peer, $localid) = each %{$self->{'localid'}}) {
            if ($localid eq $remote) {
                $self->{'localid'}{$peer} = $self->{'id'};
                $self->unicast($peer, 'META.ON', $self->{'id'});
            }
        }
        unless (exists $self->{'table'}{$arg}) {
            $self->{'peerid'}{$arg}    = $arg;
            $self->{'localid'}{$arg}   = $self->{'localid'}{$remote};
            $self->{'table'}{$arg}     = $remote;
            $self->{'peerid'}{$remote} = $arg;
        }
    }
}

# The default call back function for META.OFF.
sub _meta_off {
    my ($self, $remote, $arg) = @_;
    $self->_debug($remote);

    my $sock = $self->{'table'}{$remote};
    my $peer = $remote;

    if (ref($sock) !~ m|IO|) {
        ($peer, $sock) = ($sock, $self->{'table'}{$sock});
        $self->unicast($peer, 'META.TO', $peer);
    }
    else {
        $self->{'sel'}->remove($sock);
        $sock->close;
    }

    delete $self->{'table'}{$remote};
}

# The default call back function for META.TO.
sub _meta_to {
    my ($self, $remote, $arg) = @_;
    $self->_debug($remote, $arg);

    if (exists $self->{'table'}{$arg}) {
        if ($self->{'localid'}{$remote} ne $arg) {
            $self->{'localid'}{$remote} = $arg;
            $self->unicast($remote, 'META.ON', $arg);
        }
        if ($self->{'localid'}{$arg} ne $remote) {
            $self->{'localid'}{$arg} = $remote;
            $self->unicast($arg, 'META.ON', $remote);
        }
    }
    else {
        $self->unicast($remote, 'META.ON', $self->{'id'});
    }
}

# ------------------------------------
# Subroutine hook($self, $plan, \&sub)
# ------------------------------------
sub hook {
    my $self = shift;

    unshift @{$self->{'hook'}{$_[0]}}, $_[1];

    return [$_[0], $#_];
}

# ---------------------------------
# Subroutine unhook($self, @hookid)
# ---------------------------------
sub unhook {
    my $self = shift;

    foreach my $hook (@_) {
        $self->{'hook'}{$hook->[0]}[$hook->[1]] = undef;
    }

    return $#_;
}

# -----------------------------------
# Subroutine findhook($self, [$hook])
# -----------------------------------
sub findhook {
    die 'Findhook is not implemented';
}

# ---------------------------------------------
# Subroutine installhook($self, $remote, $hook)
# ---------------------------------------------
sub installhook {
    die 'Installhook is not implemented';
}

# -------------------------------------------------------------
# Subroutine multicast($self, \@remotes, $cmd, [$arg], [$data])
# -------------------------------------------------------------
sub multicast {
    die 'Multicast is not implemented';
}

# -----------------------------
# Subroutine spawn($self, @opt)
# -----------------------------
sub spawn {
    die 'Spawn is not implemented';
}

# direct communication
sub _contact_direct {
    my $self   = shift;
    my $remote = shift;
    my $sock   = IO::Socket::INET->new(PeerAddr => shift || 'localhost',
                                       PeerPort => shift || '7978',
                                       Proto    => shift || 'tcp') or return;
    $sock->autoflush(1);
    $sock->timeout($self->{'timeout'});
    $self->_send($sock, "META.ON $self->{'id'}\015\012");

    while (my $line = $sock->getline() or return) {
        if ($line =~ m|^META\.ON (.+?)[\015\012]*$|) {
            $remote ||= $1;
            if ($remote ne $1) {
                $self->_send($sock, "META.TO $remote\015\012");
                $sock->getline() =~ m|^META\.ON (.+)\015\012$| or return;
                $remote eq $1 or return;
            }
            last;
        }
    }

    $self->{'table'}{$remote}   = $sock;
    $self->{'localid'}{$remote} = $self->{'id'};
    $self->{'peerid'}{$remote}  = $remote;

    $self->{'socks'}{$sock->fileno} = $remote;
    $self->{'sel'}->add($sock);

    return 1;
}


# local communication
sub _contact_local {
    my $self   = shift;
    my $remote = shift;

    return unless exists $Cells{$remote};

    $Cells{$remote}->{'table'}{$self->{'id'}}   = $self->{'id'};
    $Cells{$remote}->{'localid'}{$self->{'id'}} = $remote;
    $Cells{$remote}->{'peerid'}{$self->{'id'}}  = $self->{'id'};

    $self->{'table'}{$remote}   = $remote;
    $self->{'localid'}{$remote} = $self->{'id'};
    $self->{'peerid'}{$remote}  = $remote;

    return 1;
}

# relay communication
sub _contact_relay {
    my $self   = shift;
    my $remote = shift;

    while (my ($peer, $sock) = each %{$self->{'table'}}) {
        next unless ref($sock);

        $self->unicast($peer, 'META.TO', $remote);
        $self->RunCells(1, sub { $self->{'peerid'}{$peer} eq $remote });

        $self->{'table'}{$remote}   = $peer;
        $self->{'localid'}{$remote} = $self->{'id'};
        $self->{'peerid'}{$remote}  = $remote;

        return 1;
    }

    return;
}

# -------------------------------------------------------------
# Subroutine contact($self, [$target, $addr, $port, $protocol])
# -------------------------------------------------------------
sub contact {
    my $self = shift;

    return ($self->{'table'} and exists($self->{'table'}{$_[0]})
        or ($_[1] and $self->_contact_direct(@_))
        or ($_[0] and ($self->_contact_local(@_)
                    or $self->_contact_relay(@_))));
}

# --------------------------------------------------
# Subroutine broadcast($self, $cmd, [$arg], [$data])
# --------------------------------------------------
sub broadcast {
    my $self = shift;

    $self->_debug(@_);

    while (my ($peer, $sock) = each %{$self->{'table'}}) {
        next if ref($sock);
        $self->unicast($peer, @_);
    }

    while (my ($peer, $sock) = each %{$self->{'table'}}) {
        next unless ref($sock);
        $self->unicast($peer, @_);
    }

}

# ---------------------------------------------------------
# Subroutine unicast($self, $remote, $cmd, [$arg], [$data])
# ---------------------------------------------------------
sub unicast {
    my $self = shift;

    $self->_debug(@_);

    my $remote = shift or return;
    my ($cmd, $arg, $data) = @_ or return;

    my $peer = $remote;
    my $sock = $self->{'table'}{$peer};

    if ($sock eq $peer) {
        $Cells{$remote}->_check_message($self->{'id'}, $cmd, $arg, $data);
        return 1;
    }
    elsif (ref($sock) !~ m|IO|) {
        # relay!
        ($peer, $sock) = ($sock, $self->{'table'}{$sock});
    }

    my $output = $cmd . (defined $arg ? " $arg" : '') .
                 (defined $data ? ' ' . length($data) . "\015\012" . $data
                                : "\015\012");

    if ($self->{'peerid'}{$peer} ne $remote) {
        $output = "META.TO $remote\015\012" . $output;
    }

    $self->_send($sock, $output);
}

# Send something to somebody, then check for other cells
sub _send {
    eval { $_[1]->write($_[2], length($_[2])) };
    $_[0]->_checkrest();
}

# Check all live instances except for $self.
sub _checkrest {
    my $self = shift;

    foreach my $others (values(%Cells)) {
        $others->check() unless $self eq $others;
    }
}

# Accept a new socket
sub _contact_accept {
    my $self = shift;
    my $sock = shift->accept;

    $sock->autoflush(1);
    $sock->timeout($self->{'timeout'});

    while (my $line = $sock->getline() or ($sock->close, return)) {
        next unless $line =~ m|^META\.ON (.+?)[\015\012]*$|;

        my $remote = $1;
        $self->_send($sock, "META.ON $self->{'id'}\015\012");

        $self->{'table'}{$remote}   = $sock;
        $self->{'localid'}{$remote} = $self->{'id'};
        $self->{'peerid'}{$remote}  = $remote;

        $self->{'socks'}{$sock->fileno} = $remote;
        $self->{'sel'}->add($sock);

        $self->_debug("Accepted $remote");

        return 1;
    }
}

# Check for message and handles relay.
sub _check_message {
    my ($self, $peer, $cmd, $arg, $data) = @_;

    $self->_debug("Msg", $self->{'localid'}{$peer}, $self->{'peerid'}{$peer},
                  $cmd, $arg, $data);

    if ($cmd =~ m|^META\.|i or ($self->{'localid'}{$peer} eq $self->{'id'})) {
        # That's for me
        foreach my $routine (@{$self->{'hook'}{$cmd}}) {
            last unless (&$routine($self, $self->{'peerid'}{$peer},
                                   $arg, $data) eq BYPASS);
        }
    }
    elsif (exists $self->{'localid'}{$self->{'localid'}{$peer}}) {
        # For somebody I know
        if ($self->{'localid'}{$self->{'localid'}{$peer}} ne $peer) {
            $self->unicast($self->{'localid'}{$peer}, 'META.ON', $peer);
        }
        $self->_debug("Relay attempted to $self->{'localid'}{$peer}");
        $self->unicast($self->{'localid'}{$peer}, $cmd, $arg, $data);
    }
}

# -----------------------------------------------------------------
# Subroutine check([$self])
# -----------------------------------------------------------------
# Checks for any incoming message to $self; Could also be called as
# a class method, at which time it checks every instances once.
# -----------------------------------------------------------------
sub check {
    my $self = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : undef;

    return RunCell(0) if !$self;

    foreach my $sock ($self->{'sel'}->can_read(0)) {
        my $peer = $self->{'socks'}{$sock->fileno};

        if ($peer eq $sock) {
            # new connection
            $self->_contact_accept($sock);
        }
        elsif (my $line = $sock->getline()) {
            next unless $line =~ m|^([\w\.]+)(?:\s+(.*?))[\015\012]*$|;
            my ($cmd, $arg, $data) = ($1, $2);
            $sock->read($data, $1) if ($cmd =~ m|^WRITE\.|i and $arg =~ s|\s(\d+)$||);

            $self->_check_message($peer, $cmd, $arg, $data);
        }
    }
}

sub off {
    my $self = shift;
    $self->broadcast('META.OFF');
}

1;

__END__

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2000 by Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself for
non-commercial uses.

=cut
