package OurNet::BBS::Base;

use strict;

sub daemonize {
    require OurNet::BBS::PlServer;
    OurNet::BBS::PlServer->daemonize(@_);
}

sub new {
    my $class = shift;
    my ($self, $proxy);

    tie %{$self}, $class, @_;
    no strict 'refs';

    if (exists(${"$class\::FIELDS"}{_phash})) {
        require OurNet::BBS::ArrayProxy;
        tie @{$proxy}, 'OurNet::BBS::ArrayProxy', $self;
    }

    return bless($proxy || $self, $class);
}

sub STORE {
    die "@_: STORE unimplemented";
}

sub DELETE {
    my ($self, $key) = @_;

    $self->refresh($key);
    return unless exists $self->{_cache}{$key};

    my $ego = $self->{_cache}{$key};

    $ego = tied(%{$ego})
        ? UNIVERSAL::isa(tied(%{$ego}), 'OurNet::BBS::ArrayProxy')
            ? tied(%{tied(%{$ego})->{_hash}})
            : tied(%{$ego})
        : $ego;

    $ego->remove() or die "can't DELETE $key: $!";
    return delete($self->{_cache}{$key});
}

sub DESTROY {}
sub INIT    {}
sub CLEAR   {}

# Base Tiehash
sub TIEHASH {
    my $class = $_[0];
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };
    no strict 'subs';

    if (!UNIVERSAL::can($class, '__accessor')) {
        no strict 'refs';
        foreach my $property (keys(%{$self}), '__accessor') {
            *{"${class}::$property"} = sub {
                my $self = shift;
                my $ego = tied(%{$self})
                    ? UNIVERSAL::isa(tied(%{$self}), "OurNet::BBS::ArrayProxy")
                        ? tied(%{tied(%{$self})->{_hash}})
                        : tied(%{$self})
                    : $self;

                $ego->refresh();
                $ego->{$property} = $_[1] if $_[1];
                return $ego->{$property};
            };
        }
    }

    if (0 and $#_ = 0 and UNIVERSAL::isa($_[0], 'HASH')) {
        # Passed in a single hashref -- assign it!
        %{$self} = %{$_[0]};
    }
    else {
        # Automagically fill in the fields.
        foreach my $key (keys(%{$self})) {
            $self->{$key} = $_[$self->[0]{$key}];
        }
    }
    # print "magic sayth $self->{recno}\n" if $class eq 'OurNet::BBS::CVIC::Article';

    bless $self, $class;
    return $self;
}

sub FETCH {
    my ($self, $key) = @_;

    if (exists($self->{_phash})) {
        ${$self->{_phash}[1]} = $key;
        return 1;
    }
    else {
        $self->refresh($key);
        return $self->{_cache}{$key};
    }
}

sub EXISTS {
    my ($self, $key) = @_;

    $self->refresh($key);

    return (exists $self->{_cache}{$key} or
           (exists $self->{_phash} and
            exists $self->{_phash}[0]{$key})) ? 1 : 0;
}

sub FIRSTKEY {
    my $self = shift;

    $self->refresh();
    local $_ = (exists $self->{_phash})
                   ? keys (%{$self->{_phash}[0]})
                   : keys (%{$self->{_cache}});

	return $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;

    if (exists $self->{_phash}) {
        return each %{$self->{_phash}[0]};
        if ($self->{_phash}[2] < @{$self->{_phash}[0]}) {
            my $obj = $self->{_phash}[0][$self->{_phash}[2]];
    	    return ($obj->name, $obj);
        }
        else {
            $self->{_phash}[2] = 0;
            return;
        }
    }
    else {
        return each %{$self->{_cache}};
    }
}

sub refresh {
    my ($self, $key, $arrayfetch) = @_;

    my $ego = tied(%{$self})
        ? UNIVERSAL::isa(tied(%{$self}), 'OurNet::BBS::ArrayProxy')
            ? tied(%{tied(%{$self})->{_hash}})
            : tied(%{$self})
        : $self;

    my $method = 'refresh_' .
                 ($key && $ego->can("refresh_$key") ? $key : 'meta');

    return $ego->$method($key, $arrayfetch);
}


1;
