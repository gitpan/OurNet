package OurNet::BBS::CVIC::Group;

$OurNet::BBS::CVIC::Group::VERSION = "0.1";

use File::stat;
use base qw/OurNet::BBS::Base/;
use fields qw/bbsroot group mtime _cache/;

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/group/$self->{group}";
    my $board;

    return unless $self->{group};
    local *GROUP;

    return if $self->{mtime} and stat($file)->mtime == $self->{mtime};

    open (GROUP, $file) or open (GROUP, "+>>$file")
        or confess("Cannot read group file $file: $!");

    $self->{mtime} = stat($file)->mtime;

    my %remain = %{$self->{_cache} || {}};
    while ($key = <GROUP>) {
        $key = $1 if $key =~ m/(\w+)/;
	delete $remain{$key};
        next if exists $self->{_cache}{$key};

        if (-e "$self->{bbsroot}/group/$key") {
            $self->{_cache}{$key} = OurNet::BBS::CVIC::Group->new(
                $self->{bbsroot}, $key
            );
        }
        elsif (substr($key, 0, 1) eq '+' and
               -e "$self->{bbsroot}/group/".($key = substr($key, 1))) {
            %{$self->{_cache}} = (
                %{$self->{_cache}},
                %{OurNet::BBS::CVIC::Group->new($self->{bbsroot}, $key)},
            );
        }
        elsif (-e "$self->{bbsroot}/boards/$key/.DIR") {
            require OurNet::BBS::CVIC::Board;

            $self->{_cache}{$key} = OurNet::BBS::CVIC::Board->new(
                $self->{bbsroot}, $key
            );
        }
    }
    foreach my $del (keys(%remain)) {
	delete $self->{_cache}{$del};
    }
    close GROUP;
}

sub DELETE {
    my ($self, $key) = @_;
    my $file = "$self->{bbsroot}/group/$self->{group}";

    $self->refresh($key);
    # print join(',', keys(%{$self->{_cache}}));
    return unless delete($self->{_cache}{$key});

    open GROUP, $file or die "Cannot read group file $file: $!";
    my $content = join ('', grep { not m/\b$key\b/ } <GROUP>);
    close GROUP;

    open GROUP, ">$file" or die "Cannot write group file $file: $!";
    print GROUP $content;
    close GROUP;
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $file = "$self->{bbsroot}/group/$self->{group}";

    return if exists $self->{_cache}{$key}; # doesn't make sense yet
    die "doesn't exists such group or board $key: panic!"
        unless (-e "$self->{bbsroot}/group/$key" or
                -e "$self->{bbsroot}/boards/$key/.DIR");

    open GROUP, ">>$file" or die "Cannot append group file $file: $!";
    print GROUP $key, "\n";
    close GROUP;
}

sub remove {
    my $self = shift;
    return unlink(join('/', $self->{bbsroot}, 'group', $self->{group}));
}

1;
