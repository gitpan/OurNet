use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 2 }

# Load BBS
use OurNet::BBS;

$OurNet::BBS::DEBUG++;
$OurNet::BBS::DEBUG++;

my $BBS;
ok($BBS = OurNet::BBS->new('BBSAgent', 'openbazaar'));
my $brd = $BBS->{boards};
ok(index($brd->{Announce}{articles}[1]{title}, 'BBS') > -1);

__END__
