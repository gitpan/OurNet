package OurNet::BBS::Utils;

sub deltree {
    use File::Find;

    my $dir = shift or return;

    finddepth(sub {
        if (-d $File::Find::name) {
            rmdir $File::Find::name;
        }
        else {
            unlink $File::Find::name;
        }
    }, $dir) if -d $dir;

    rmdir $dir;
}

sub locate {
    my $path = (caller)[0];
    my $file = $_[0];

    $path =~ s|::|/|g;
    $path =~ s|\w+$||;

    unless (-e $file) {
        foreach my $inc (@INC) {
            last if -e ($file = join('/', $inc, $_[0]));
            last if -e ($file = join('/', $inc, $path, $_[0]));
        }
    }

    return -e $file ? $file : undef;
}

1;
