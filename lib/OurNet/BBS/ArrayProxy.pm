package OurNet::BBS::ArrayProxy;

sub FETCHSIZE {
    my $self = shift;
    my $ego  = (tied %{$self->{_hash}});

    $ego->refresh();

    return (($#{$ego->{_phash}[0]} + 1) || 1);
}

sub TIEARRAY {
    my ($class, $hash) = @_;
    my $flag = undef;
    my $self = {_flag => \$flag, _hash => $hash};

    (tied %$hash)->{_phash}[1] = (\$flag);
    return bless($self, $class);
}

sub PUSH {
    my $self = shift;
    my $ego  = (tied %{$self->{_hash}});
    my $size = (($#{$ego->{_phash}[0]} + 1) || 1);

    foreach my $item (@_) {
        $self->STORE($size++, $item);
    }
}

sub STORE {
    my $self = shift;
    my $key  = shift;
    my $ego  = (tied %{$self->{_hash}});

    $ego->STORE(
        defined(${$self->{_flag}}) ? ${$self->{_flag}}
                                   : $key,
        @_
    );
}

sub DELETE {
    my $self = shift;
    my $key  = shift;
    my $ego  = (tied %{$self->{_hash}});

    $ego->DELETE(
        defined(${$self->{_flag}}) ? ${$self->{_flag}}
                                   : $key,
        @_
    );
}

sub EXISTS {
    my ($self, $key) = @_;
    my $ego  = (tied %{$self->{_hash}});

    # if (defined(${$self->{_flag}})) { # XXX perl can't exists phash
    #     return $ego->EXISTS(${$self->{_flag}});
    # }
    # else {
        $ego->refresh($key, 1);
        return $ego->{_phash}[0][$key] ? 1 : 0;
    # }
}

sub FETCH {
    my ($self, $key) = @_;
    my $hash = $self->{_hash};
    return $hash if $key == 0;
    # print "$self AFETCH: $key\n";
    my $ego = tied %{$hash};

    if (defined ${$self->{_flag}}) {
        $key = ${$self->{_flag}};
        undef ${$self->{_flag}};
        # print "ensues $key!\n";
        $ego->refresh($key);
        # print "fetching: ${$self->{_flag}}\n";
        return (exists $ego->{_phash}[0] and exists $ego->{_phash}[0][0]{$key})
            ? $ego->{_phash}[0]{$key}
            : $ego->{_cache}{$key};
    }
    else {
        # print "ensues $key.\n";
        $ego->refresh($key, 1);
        # die "$key $#{(tied %{$hash})->{_phash}[0]}\n";
        return $ego->{_phash}[0][$key];
    }
}

sub CLEAR {};
sub EXTEND {};
1;
