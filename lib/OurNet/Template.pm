# XXX WARNING: This has *absolutely* no practical use.   XXX #
# XXX No interface is stable. Hack it at your own peril. XXX #

# This code used to be much longer, but thanks to Pattern Designs,
# much of those are obsolete & outdated. :-( I'll port more of
# them in the coming days. -- autrijus 2000/10/11 12:27am

package OurNet::Template;
require 5.005;

$OurNet::Template::VERSION = '0.01';

use Template '2.00-beta5';
use Template::Parser;

use strict;
use lib qw/./;
use vars qw/@ISA $params @stack %idea/;

@ISA = qw/Template/;

sub generate {
    my ($self, $params, $document) = @_;
    die "Template Generation, the holy grail, is of yet unsupported.";
}


sub extract {
    my ($self, $template, $document) = @_;
    my ($output, $error);
    $params = {@stack = %idea = ()};

    my $parser = Template::Parser->new({
        PRE_CHOMP => 1,
        POST_CHOMP => 1,
    });

    $parser->{ FACTORY } = 'OurNet::Extract';
    my $regex = $parser->parse(ref($template) eq 'SCALAR' ? $$template : $template)->{ BLOCK };
    # print "Regex: [$regex]";

    use re 'eval';
    return $document =~ /$regex/s ? $params : undef;
}

sub _set {
    my ($var, $val, $num, $pos, $loop) = @_;

    if ($loop) {
        $idea{$num}{$pos} ||= $idea{$loop}{$num}++;
        $params->{$loop}[$idea{$num}{$pos} - 1]{$var} = $val
            if $idea{$num}{$pos};
    }
    else {
        $params->{$var} = $val;
    }
    return;
}

1;


package OurNet::Extract;
$OurNet::Extract::VERSION = '0.01';

require 5.005;
use strict;
use vars qw/$AUTOLOAD $count/;

$count = 0;

sub template {
    $count = 0;
    return $_[1];
}

sub block {
    return join("", @{ $_[1] || [] });
}

sub ident {
    return $_[1][0];
}

sub get {
    if ($_[1] eq "'_'") {
        return '(?:.*?)';
    }
    else {
        $count++;
        return "(.*?)(?{
    _set($_[1], \$$count, $count, \$-[$count]) ###
})";
    }
}

sub textblock {
    return quotemeta($_[1]);
}

sub foreach {
    my $reg = $_[4];
    $reg =~ s/\]\) ###/], $_[2])/g;
    return "(?:$reg)*";
}

# This has absolutely no use
sub AUTOLOAD {
    use Data::Dumper;
    $Data::Dumper::Indent = 1;
    my $output = "\n$AUTOLOAD -";
    for my $arg (1..$#_) {
        $output .= "\n    [$arg]: ";
        $output .= ref($_[$arg]) ? Data::Dumper->Dump([$_[$arg]], ['_']) : $_[$arg];
    }
    return $output;
}

1;


package OurNet::Generate;
$OurNet::Generate::VERSION = '0.01';

require 5.005;
use strict;
use vars qw/$AUTOLOAD $count/;


1;
