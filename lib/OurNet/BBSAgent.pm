package OurNet::BBSAgent;
require 5.005;

$OurNet::BBSAgent::VERSION = '1.1';

use strict;
use lib qw/./;
use vars qw/$AUTOLOAD/;
use Net::Telnet;

=head1 NAME

OurNet::BBSAgent - Scriptable telnet-based virtual users

=head1 SYNOPSIS

    # To run it, make sure you have a 'cvic.bbs' file in the same
    # directory. Its contents is listed just below this section.

    use OurNet::BBSAgent;

    my $cvic = new OurNet::BBSAgent('cvic.bbs', undef, 'testlog');

    # $cvic->{'debug'} = 1; # Turn on for debugging

    $cvic->login($ARGV[0] || 'guest', $ARGV[1]);
    print "now at $cvic->{'state'}";
    $cvic->Hook('balloon', \&callback);
    $cvic->Loop;

    sub callback {
        ($caller, $message) = @_;
        print "Received: $message\n";
        exit if $message eq '!quit';
        $cvic->balloon_reply("$caller, I've got your message!");
    }

=head1 DESCRIPTION

OurNet::BBSAgent provides an object-oriented interface to TCP/IP-based
interactive services (e.g. BBS, IRC, ICQ and Telnet), by simulating as
a "virtual user" with action defined by a script language. The developer
could then use the same methods to access different services, to easily
implement interactive robots, spiders, or other cross-service agents.

=head2 Site Description File

This module has its own scripting language, which looks like this in
a site description file:

    CVIC BBS
    cvic.org:23

    =login
    wait 註冊
      or 使用者
    send $[username]\n
    doif $[password]
        wait 密碼
        send $[password]\n\n
    endo
    send \n\n\n
    goto main

    =main
    send eeeeeeee
    wait 主功能表
    till Call機

    =balloon
    wait \e[1;33;46m★
    till \e[37;45m\x20
    till \x20\e[0m
    exit

    =balloon_reply
    send \x12
    wait 回去：
    send $[message]\n
    wait [Y]
    send \n
    wait \e[m
    exit

The first two lines describes the service's title, its IP address and
port number. Any number of 'procedures' then begins with C<=procname>,
which could be called like C<$object->procname([arguments])> in the
program. Each procedure is made by any number of following directives:

=over

=item wait STRING
=item till STRING
=item   or STRING

Tells the agent to wait until STRING is sent by remote host. Might time
out after C<$self->{'timeout'}> seconds. Any trailing C<or> directives
specifies an alternative string to match.

Additionally, C<till> puts anything between the last C<wait> or C<till>
and STRING into the return list.

=item send STRING

Sends STRING to remote host.

=item doif CONDITION
=item else CONDITION
=item endo

The usual flow control directives. Nested C<doif...endo>s is supported.

=item goto PROCEDURE
=item call PROCEDURE

Executes another procedure in the site description file. C<goto> never
returns, while C<call> always will. Also, a C<call> will not occur if
the destination was the last executed procedure that does not end with
C<exit>.

=item exit

Marks the termination of a procedure; also means this procedure is not
a 'state' - that is, multiple C<call>s to it will all be executed.

=item back

=head2 Event Hooks

In addition to call the procedures one-by-one, you can 'hook' those
that begins with 'wait' (or 'call' and 'wait') so whenever the strings
they expected are received, the responsible procedure is immediately
called. You can also supply a call-back function to handle its results.

For example, the code in L</SYNOPSIS> above 'hooks' a callback function
to procedure 'balloon', then enters a event loop by calling C<Loop>,
which never terminates except when the agent receives '!quit' via the
balloon procedure.

The internal hook table could be accessed by $obj->{'hook'}. It is
implemented via a hash of hash of hash of lists -- Kids, don't try
this at home!

=cut

# ---------------
# Variable Fields
# ---------------
use fields qw/bbsname bbsaddr bbsport bbsfile
              debug timeout state proc var netobj hook loop/;

# --------------------------------------------
# Subroutine new($bbsfile, $timeout, $logfile)
# --------------------------------------------
sub new {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs'; bless [\%{"$class\::FIELDS"}], $class };

    $self->{'bbsfile'} = shift;
    $self->{'timeout'} = shift;

    die("Cannot find bbs definition file: $self->{'bbsfile'}")
        unless -e $self->{'bbsfile'};

    open(local *_FILE, $self->{'bbsfile'});

    chomp($self->{'bbsname'} = <_FILE>);
    chomp(my $addr = <_FILE>);

    if ($addr =~ /^(.*?)(:\d+)?$/) {
        $self->{'bbsaddr'} = $1;
        $self->{'bbsport'} = substr($2, 1) || 23;
    }
    else {
        die("Malformed location line: $addr");
    }

    while (my $line = <_FILE>) {
        chomp $line;
        next if $line =~ /^#|^\s*$/;

        if ($line =~ /^=(\w+)$/) {
            die("Duplicate definition on procedure $1")
                if exists($self->{'proc'}{$1});

            $self->{'state'}    = $1;
            $self->{'proc'}{$1} = [];
        }
        elsif ($line =~ /^\s*(doif|endo|goto|call|wait|send|else|till|exit)\s*(.*)$/) {
            die('Not in a procedure') unless $self->{'state'};

            push @{$self->{'proc'}{$self->{'state'}}}, $1, $2;
        }
        elsif ($line =~ /^\s*or\s*(.+)$/) {
            die('Not in a procedure') unless $self->{'state'};
            die('"or" directive not after a "wait" or "till"')
                unless $self->{'proc'}{$self->{'state'}}->[-2] eq 'wait'
                    or $self->{'proc'}{$self->{'state'}}->[-2] eq 'till';

            ${$self->{'proc'}{$self->{'state'}}}[-1] .= "\n$1";
        }
        else {
            warn("Error parsing '$line'");
        }
    }

    $self->{'netobj'} = Net::Telnet->new('Timeout' => $self->{'timeout'});
    $self->{'netobj'}->open('Host' => $self->{'bbsaddr'},
                            'Port' => $self->{'bbsport'});
    $self->{'netobj'}->output_record_separator('');
    $self->{'netobj'}->input_log($_[0]) if $_[0];

    $self->{'state'} = '';

    return $self;
}

# ---------------------------------------
# Subroutine Unhook($self, $procedure)
# ---------------------------------------
# Unhooks the procedure from event table.
# ---------------------------------------
sub Unhook {
    my $self = shift;
    my $sub  = shift;

    if (exists $self->{'proc'}{$sub}) {
        my ($state, %var);
        my @proc = @{$self->{'proc'}{$sub}};

        $state = $self->_chophook(\@proc, \%var, \@_);

        print "Unhook $sub\n" if $self->{'debug'};
        delete $self->{'hook'}{$state}{$sub};
    }
    else {
        die "Unhook: undefined procedure '$sub'";
    }
}

# -----------------------------------------------------------
# Subroutine Unhook($self, $procedure, [\&callback], [@args])
# -----------------------------------------------------------
# Adds a procedure from event table, with optional callback
# functions and procedure parameters.
# -----------------------------------------------------------
sub Hook {
    my $self = shift;
    my ($sub, $callback) = splice(@_, 0, 2);

    if (exists $self->{'proc'}{$sub}) {
        my ($state, $wait, %var) = '';
        my @proc = @{$self->{'proc'}{$sub}};

        ($state, $wait) = $self->_chophook(\@proc, \%var, [@_]);

        print "Hook $sub: State=$state, Wait=$wait\n" if $self->{'debug'};

        $self->{'hook'}{$state}{$sub} = [$sub, $wait, $callback, @_];
    }
    else {
        die "Hook: Undefined procedure '$sub'";
    }
}

# -------------------------------------------------------------
# Subroutine Loop($self, [$timeout])
# -------------------------------------------------------------
# Loops for $timeout seconds, or indefinitely if not specified.
# -------------------------------------------------------------
sub Loop {
    my $self = shift;

    do {
        $self->Expect(undef, defined $_[0] ? $_[0] : -1);
    } until (defined $_[0]);
}

# --------------------------------------------------------------
# Subroutine Expect($self, [$string], [$timeout])
# --------------------------------------------------------------
# Implements the 'wait' and 'till' directive depends on context.
# Note multiple strings could be specified in one $string by
# using \n as delimiter.
# --------------------------------------------------------------
sub Expect {
    my $self    = shift;
    my $param   = shift;
    my $timeout = shift || $self->{'timeout'};

    if ($self->{'netobj'}->timeout() ne $timeout) {
        $self->{'netobj'}->timeout($timeout);
        print "Timeout change to $timeout\n" if $self->{'debug'};
    }

    my ($retval, $retkey, $key, $val, %wait);

    while (($key, $val) = each %{$self->{'hook'}{$self->{'state'}}}) {
        $wait{$val->[1]} = $val;
    }

    if (defined $self->{'state'}) {
        while (($key, $val) = each %{$self->{'hook'}{''}}) {
            $wait{$val->[1]} = $val;
        }
    }

    if (defined $param) {
        @wait{split('\n', $param)} = undef;
    }

    # Let's see the counts...
    my @keys = keys(%wait) or return;

    print "Waiting: [",join(",", @keys),"]\n" if $self->{'debug'};

    if (defined wantarray or $#keys) {
        eval {
            ($retval, $retkey) =
                ($self->{'netobj'}->waitfor(map {('String' => $_)} @keys));
        }
    }
    else {
        eval {
            $self->{'netobj'}->waitfor(map {('String' => $_)} @keys);
            $retkey = $keys[0];
        }
    }

    (die $@, return) if ($@);

    if ($wait{$retkey}) {
        # Hook call.
        $AUTOLOAD = $wait{$retkey}->[0];

        if (ref($wait{$retkey}->[2]) eq 'CODE') {
            print "1";
            &{$wait{$retkey}->[2]}(
                # &{$wait{$retkey}->[0]}
                $self->AUTOLOAD(\'1', @{$wait{$retkey}}[3..$#{$wait{$retkey}}])
            );
        }
        else {
            print "2";
            $self->AUTOLOAD(\'1', @{$wait{$retkey}}[3..$#{$wait{$retkey}}])
        }
    }
    else {
        # Direct call.
        return (defined $retval ? $retval : '') if defined wantarray;
    }
}

# Chops the first one or two lines from a procedure to determine
# if it could be used as a hook, among other things.
sub _chophook {
    my $self = shift;
    my ($procref, $varref, $paramref) = @_;
    my ($state, $wait);
    my $op = shift(@{$procref});

    if ($op eq 'call') {
        $state = shift(@{$procref});
        $state =~ s/\$\[(.+?)\]/$varref->{$1} ||
                               ($varref->{$1} = shift(@{$paramref}))/eg;

        # Chophook won't cut the wait op under scalar context.
        return $state if (defined wantarray xor wantarray);

        $op    = shift(@{$procref});
    }

    if ($op eq 'wait') {
        $wait = shift(@{$procref});
        $wait =~ s/\$\[(.+?)\]/$varref->{$1} ||
                              ($varref->{$1} = shift(@{$paramref}))/eg;

        # Don't bother any more under void context.
        return unless wantarray;

        $wait =~ s/\x5c\x5c/_!!!_/g;
        $wait =~ s/\\n/\015\012/g;
        $wait =~ s/\\e/\e/g;
        $wait =~ s/\\x([0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg;
        $wait =~ s/_!!!_/\x5c/g;
    }
    else {
        die "Chophook: Procedure does not start with 'wait'";
    }

    return ($state, $wait);
}

# Implementation of named procedures.
sub AUTOLOAD {
    my $self   = shift;
    my $flag   = ${shift()} if ref($_[0]);
    my $params = join(',', @_) if @_;
    my $sub    = $AUTOLOAD;

    local $^W = 0; # no warnings here

    $sub =~ s/^.*:://;

    if (exists $self->{'proc'}{$sub}) {
        my @proc = @{$self->{'proc'}{$sub}};
        my @cond = 1;
        my (@result, %var);

        print "Entering $sub ($params)\n" if $self->{'debug'};

        $self->_chophook(\@proc, \%var, \@_) if $flag;

        while (my $op = shift(@proc)) {
            my $param = shift(@proc);

            ($op eq 'endo') ? do {
                pop @cond; next;
            } :
            ($op eq 'else') ? do {
                $cond[-1] = !($cond[-1]); next;
            } : do {
                next unless ($cond[-1]);
            };

            if ($self->{'debug'}) {
                my $pp = $param;
                $pp =~ s/\$\[(.+?)\]/$var{$1} || ($var{$1} = shift)/eg;
                print "*** $op $pp\n";
            }

            $param =~ s/\x5c\x5c/_!!!_/g;
            $param =~ s/\\n/\015\012/g;
            $param =~ s/\\e/\e/g;
            $param =~ s/\\x([0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg;
            $param =~ s/_!!!_/\x5c/g;

            $param =~ s/\$\[(.+?)\]/$var{$1} || ($var{$1} = shift)/eg;

            if ($op eq 'doif') {
                push(@cond, $param);
            }
            elsif ($op eq 'call') {
                my $subparam = $1 if ($param =~ s/\s+(.*)//);
                $self->$param(split(',', $subparam))
                    unless $self->{'state'} eq "$param $subparam";
            }
            elsif ($op eq 'goto') {
                $self->$param() unless $self->{'state'} eq $param;
                return wantarray ? @result : $result[0];
            }
            elsif ($op eq 'wait') {
                defined $self->Expect($param) or return;
            }
            elsif ($op eq 'till') {
                my $lastidx = $#result;
                push @result, $self->Expect($param);
                return if $lastidx == $#result;
            }
            elsif ($op eq 'send') {
                eval { $self->{'netobj'}->send($param) };
                return if $@;
            }
            elsif ($op eq 'exit') {
                $self->{'var'} = {};
                $result[0] = '' unless defined $result[0];
                return wantarray ? @result : $result[0];
            }
            else {
                die "No such operator: $op";
            }
        }

        $self->{'var'}   = {};
        $self->{'state'} = "$sub $params";

        print "Set State: $self->{'state'}\n" if $self->{'debug'};
        return wantarray ? @result : $result[0];
    }
    else {
        die "Undefined procedure '$sub' called";
    }
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
