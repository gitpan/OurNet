package OurNet::BBS::Utils;
use vars qw/$hostname/;
use strict;

use Sys::Hostname;
$hostname = &Sys::Hostname::hostname();

sub deltree {
    require File::Find;

    my $dir = shift or return;

    File::Find::finddepth(sub {
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
    $path =~ s|/\w+$||;

    unless (-e $file) {
        foreach my $inc (@INC) {
            last if -e ($file = join('/', $inc, $_[0]));
            last if -e ($file = join('/', $inc, $path, $_[0]));
        }
    }

    return -e $file ? $file : undef;
}

# arg: timestamp author board host
sub get_msgid {
    my ($timestamp, $author, $board, $host) = @_;

    $host ||= $hostname;

    use Date::Parse;
    use Date::Format;
    use Digest::MD5 'md5_base64';

    if ($timestamp !~ /^\d+$/) {
        # conversion from ctime format
        $timestamp = str2time($timestamp);
    }

    $timestamp = time2str('%Y%m%d%H%M%S', $timestamp)
        unless length($timestamp) == 14;

    return $timestamp.'.'.md5_base64("$board $author").'@'.$host;
}

1;
