package OurNet;
require 5.005;

$OurNet::VERSION = '1.5';

use strict;

=head1 NAME

OurNet - Interface to BBS-based groupware platforms

=head1 SYNOPSIS

    # import modules automatically
    use OurNet qw/FuzzyIndex BBS BBSApp/;

    # the rest of code...
    my $BBS = OurNet::BBS->new(@ARGV); # etc

=head1 MODULES

    ::BBS        bmpO    Component Object Model for BBS systems
    ::BBSApp     ampO    BBS Application platform
    ::BBSAgent   RmpO    Scriptable telnet-based virtual users
    ::ChatBot    RmpO    Context-free interactive Q&A engine
    ::FuzzyIndex RmcO    Inverted index for double-byte charsets
    ::Query      RmpO    Perform scriptable queries via LWP
    ::Site       RmpO    Extract web pages via templates
    ::Template   ampO    Template extraction and generation
    ::WebBuilder RmpO    HTML rendering for BBS-based services

=head1 SCRIPTS

    fzindex     FuzzyIndex index utility
    fzquery     FuzzyIndex query utility
    bbscomd     BBS RPC daemon
    bbsappd     BBS internal application daemon
    sitequery   Metasearch using Query and Site modules

=head1 DESCRIPTION

The OurNet:* modules are interfaces to BBS-based groupware projects,
whose platform was used in Hong Kong, China and Taiwan by est. 1
million users. Used collaboratively, they glue BBSes together to form
a distributed service network, called 'OurNet'.

Please refer to each individual modules and script's documentation
for detailed information.

=head1 CAVEATS

The HOWTO documentation and BBSCOM API is still lacking; we'll be very
grateful if anybody from the BBS circle could contribute to it.

=cut

sub import {
    my $self = shift;
    my $package = (caller())[0];

    my @failed;

    foreach my $module (@_) {
        eval("package $package; use OurNet::$module;");

        if ($@) {
            warn $@;
            push(@failed, $module);
        }
    }

    die "could not import qw(" . join(' ', @failed) . ")" if @failed;
}

sub new {
    my $class  = shift;
    my $module = shift;

    require "${class}/$module.pm";
    return "${class}::$module"->new(@_);
}

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

=cut
