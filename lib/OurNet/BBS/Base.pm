package OurNet::BBS::Base;
$VERSION = '0.1';

use strict;

sub initvars {
    no strict 'refs';

    my $class = shift;
    my $backend = $1 if scalar caller() =~ m|^OurNet::BBS::(\w+)|;
    my ($ch, $sym);
    # print "initing: $class\n";

    # inheritance magic
    foreach my $parent (@{"${class}::ISA"}) {
        next if $parent eq __PACKAGE__;

        while (my ($sym, $ref) = each (%{"${parent}::"})) {
            unless (defined *{"${class}::$sym"}) {
                # print "importing $sym\n";
                *{"${class}::$sym"} = $ref;
            }
        }
        # print "\n";
    }


    while (my ($mod, $symref) = splice(@_, 0, 2)) {
        if ($mod =~ m/^\w/) { # getvar
            require "OurNet/BBS/$backend/$mod.pm";
            $mod = "OurNet::BBS::${backend}::${mod}";

            while ($sym = shift(@{$symref})) {
                ($ch, $sym) = unpack('a1a*', $sym);
                *{"${class}::$sym"} = (
                    $ch eq "\$" ? \$   {"${mod}::$sym"} :
                    $ch eq "\@" ? \@   {"${mod}::$sym"} :
                    $ch eq "\%" ? \%   {"${mod}::$sym"} :
                    $ch eq "\*" ? \*   {"${mod}::$sym"} :
                    $ch eq "\&" ? \&   {"${mod}::$sym"} : ''
                );
            }
        }
        else { # setvar
            ($ch, $sym) = unpack('a1a*', $mod);
            *{"${class}::$sym"} = (
                $ch eq "\$" ? \$   {"${class}::$sym"} :
                $ch eq "\@" ? \@   {"${class}::$sym"} :
                $ch eq "\%" ? \%   {"${class}::$sym"} :
                $ch eq "\*" ? \*   {"${class}::$sym"} :
                $ch eq "\&" ? \&   {"${class}::$sym"} : ''
            );
            if ($ch eq "\$") {
                ${"${class}::$sym"} = $symref;
            }
            elsif ($ch eq "\@") {
                @{"${class}::$sym"} = @{$symref};
            }
            elsif ($ch eq "\%") {
                %{"${class}::$sym"} = %{$symref};
            }
            else {
                die "cannot expand symbol: $sym";
            }
        }
    }
}


sub getvar {
    my $backend;

    if (ref($_[0])) {
        $backend = (+shift)->backend();
    }
    else {
        $backend = $1 if scalar caller() =~ m|^OurNet::BBS::(\w+)|;
    }

    my ($mod, $var) = split('::', $_[0], 2);
    no strict 'refs';
    require "OurNet/BBS/$backend/$mod.pm";
    return wantarray ? @{"OurNet::BBS::${backend}::${mod}::${var}"}
#                   || %{"OurNet::BBS::${backend}::${mod}::${var}"}
                     : ${"OurNet::BBS::${backend}::${mod}::${var}"};
}


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

    if ($#_ == 1 and UNIVERSAL::isa($_[1], 'HASH')) {
        # Passed in a single hashref -- assign it!
        %{$self} = %{$_[1]};
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

sub backend {
    my $self = shift;

    my $ego = tied(%{$self})
        ? UNIVERSAL::isa(tied(%{$self}), 'OurNet::BBS::ArrayProxy')
            ? tied(%{tied(%{$self})->{_hash}})
            : tied(%{$self})
        : $self;

    my $backend = ref($ego);

    $backend = $1 if $backend =~ m|^OurNet::BBS::(\w+)|;

    return $backend;
}

sub module {
    my ($self, $mod) = @_;
    my $backend = $self->backend();
    require "OurNet/BBS/$backend/$mod.pm";
    return "OurNet::BBS::${backend}::${mod}";
}

1;
