package OurNet::BBS::PlClient;
$OurNet::BBS::PlClient::VERSION = '0.1';

use RPC::PlClient;
use fields qw/id remote_ref optree _phash/;
use vars qw/$DEBUG @delegators $AUTOLOAD/;

sub new {
    my $class = shift;
    my ($self, $proxy);

    tie %{$self}, $class, @_;
    tie @{$proxy}, 'OurNet::BBS::PlArrayProxy', $self;
    return bless($proxy, $class);
}

sub debug {
    print @_ if $DEBUG;
}

# spawn (moreop)
sub spawn {
    my ($self, $proxy);
    my $parent = shift;

    debug "SPAWN: $parent @_\n";

    tie %{$self}, ref($parent);
    tied(%{$self})->{id} = $parent->{id};
    tied(%{$self})->{optree} = $parent->{optree};
    tied(%{$self})->{remote_ref} = shift;

    push @{tied(%{$self})->{optree}}, @_;

    debug "[@{tied(%{$self})->{optree}}]\n";

    tie @{$proxy}, 'OurNet::BBS::PlArrayProxy', $self;
    
    return bless($proxy, ref($parent));
}

sub TIEHASH {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };
    if (@_) {
        $self->{id} = 1 + scalar @delegators; # 1 more than max
        $delegators[$self->{id}] = RPC::PlClient->new(
            'peeraddr'    => shift,
            'peerport'    => shift,
            'application' => 'OurNet::BBS::PlServer',
            'version'     => $VERSION,
            'username'    => shift,
            'password'    => shift,
        )->ClientObject('OurNet::BBS::PlServer', 'spawn');
        $self->{remote_ref} = $delegators[$self->{id}]->rootref();
    }
    
    bless $self, $class;
    return $self;
}

sub FETCH {
    my ($self, $key) = @_;
    debug "attempted: $key\n";
    ${$self->{_phash}} = $key;
    return 1;
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my ($ego, $prefix);

    debug "$self - $AUTOLOAD\n";
    return unless rindex($AUTOLOAD, '::') > -1;
    $AUTOLOAD = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);

    if (tied(%{$self})) {
        $prefix = 'OBJECT';
        $ego = tied(%{tied(%{$self})->{_hash}});
    }
    elsif (exists $self->{_hash}) {
        $prefix = 'ARRAY';
        $ego = tied(%{$self->{_hash}});
    }
    else {
        $prefix = 'HASH';
        $ego = $self;
    }

    my @callstack = ("$prefix.$AUTOLOAD", [@_]);
    debug "<call: $prefix.$AUTOLOAD (@_)>\n";
    my @result = $delegators[$ego->{id}]->invoke(@{$ego->{optree}}, @callstack);
    debug "</call>\n";
    if (defined $result[0] and $result[0] eq 'OBJECT.SPAWN') {
        debug "spawnref: $result[1]\n";
        return $ego->spawn($result[1], @callstack);
    }
    return @result;
}

1;


package OurNet::BBS::PlArrayProxy;
*OurNet::BBS::PlArrayProxy::AUTOLOAD = *OurNet::BBS::PlClient::AUTOLOAD;

sub TIEARRAY {
    my ($class, $hash) = @_;
    my $flag = undef;
    my $self = {_flag => \$flag, _hash => $hash};

    (tied %$hash)->{_phash} = (\$flag);
    return bless($self, $class);
}

sub STORE {
    my ($self, $key) = splice(@_, 0, 2);
    my $hash = $self->{_hash};
    # print "STORE: $key $hash\n";
    return $hash if $key == 0;
    # print "$self AFETCH: $key\n";
    my $ego = tied %{$hash};

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};

        # hash store: VERY CRUDE HACK!
        ${ref($ego).'::AUTOLOAD'} = '::STORE';
        return ($ego->AUTOLOAD($key, @_))[0];
    }
    else {
        ${ref($ego).'::AUTOLOAD'} = '::STORE';
        return ($ego->AUTOLOAD($key, @_))[0];
    }
}

sub FETCH {
    my ($self, $key) = @_;
    my $hash = $self->{_hash};
    # print "FETCH: $key $hash\n";
    return $hash if $key == 0;
    # print "$self AFETCH: $key\n";
    my $ego = tied %{$hash};

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};

        # hash fetch: VERY CRUDE HACK!
        ${ref($ego).'::AUTOLOAD'} = '::FETCH';
        return ($ego->AUTOLOAD($key))[0];
    }
    else {
        ${ref($ego).'::AUTOLOAD'} = '::FETCHARRAY';
        return ($ego->AUTOLOAD($key))[0];
    }
}

sub DESTROY {}
1;
