use strict;
use Test;
use lib '../lib';

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 24 }

# Load BBS
use OurNet::BBS;

my $BBS;

mkdir '/tmp';
my $prefix = "/tmp/".rand();
OurNet::BBS::Utils::deltree($prefix);
mkdir $prefix or die "Cannot make $prefix";
mkdir "$prefix/$_" or die "Cannot make $prefix/$_"
    foreach ('bbs', 'bbs/boards', 'bbs/group', 'bbs/man', 'bbs/man/boards');
open(BOARDS, ">$prefix/bbs/.BOARDS") or die "Cannot make $prefix/bbs/.BOARDS: $!";
close BOARDS;

ok($BBS = OurNet::BBS->new('CVIC', "$prefix/bbs"));

# make a board...
$BBS->{boards}{test} = {
    title => 'test board',
    bm    => 'sysop',
};

my $brd = $BBS->{boards}{test};

# BOARDS test

ok(join(',', keys(%{$BBS->{boards}})), 'test');
ok($brd->{bm}, 'sysop');
ok($brd, $BBS->{boards}{test});

# push #1
push @{$brd->{articles}}, {
    title  => 'test title',
    author => 'user',
    body   => 'bodie',
};
ok($brd->{articles}[1]{author}, 'user');

# append #2
$brd->{articles}[2] = {
    title  => 'random title',
    author => 'smart',
    body   => 'bodie',
};

ok($brd->{articles}[2]{body}, qr/smart/);

# alternative access

ok($brd->{articles}{$brd->{articles}[2]{id}}{body}, qr/smart/);

# set #1
$brd->{articles}[1] = {title => 'changed title'};
ok($brd->{articles}[1]{title}, 'changed title');

# foreach iteration
my $flag;
foreach (@{$brd->{articles}}[1..$#{$brd->{articles}}]) {
    ok($_->{body}, qr/bodie/);
    ok($_->mtime);

    unless ($flag++) {
        # iterator kludge
        $BBS->{boards}{kitty} = {
            title => 'test board',
            bm    => 'sysop',
        };
        ok($BBS->{boards}{kitty}{bm}, 'sysop');
    }
}


# each interation
while (my ($k, $v) = each (%{$brd->{articles}})) {
    ok($v->{title}, $brd->{articles}{$k}{title});
}

# archiving
push @{$brd->{archives}}, @{$brd->{articles}}[1,2];
ok($brd->{archives}[2]{title}, '¡º random title');

# archive directory
push @{$brd->{archives}}, bless ({
    title  => 'Random Directory',
    author => 'random',
}, 'OurNet::BBS::CVIC::ArticleGroup');

# is store successful?
ok($brd->{archives}[3]{author}, 'random');

# by-name fetch
my $name = $brd->{archives}[3]{id};
ok($name, $brd->{archives}[3]->name);

# push into new dir
push @{$brd->{archives}[3]}, {
    title  => 'turandot',
    author => 'aida',
    body   => 'satva',
};

ok($brd->{archives}[3][1]{title}, '¡º turandot');
ok($brd->{archives}[-1][1]{title}, '¡º turandot');

# new group
my $grp = $BBS->{groups}{home};

++$grp->{test};
ok(join('', keys(%{$BBS->{groups}})), 'home');

# group inside group
++$BBS->{groups}{rainbow}{home};
ok(join('', sort {$a cmp $b} keys(%{$BBS->{groups}})), 'homerainbow');

# delete group
delete $BBS->{groups}{home};
ok(!keys(%{$BBS->{groups}{rainbow}}));

# delete board
delete $BBS->{boards}{test};
ok(!(-e '/tmp/bbs/boards/test/.DIR'));

OurNet::BBS::Utils::deltree($prefix);
