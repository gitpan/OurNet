# Placeholder module for OurNet packages

package OurNet;

$OurNet::VERSION = '1.4-alpha3';

1;

=head1 NAME

OurNet - Interface to BBS-based groupware platforms

=head1 MODULES

    ::BBS        bmpO    Component Object Model for BBS systems
    ::BBSAgent   RmpO    Scriptable telnet-based virtual users
    ::Cell       ampO    Interface-based RPC with Relay & Locating
    ::ChatBot    RmpO    Context-free interactive Q&A engine 
    ::FuzzyIndex RmcO    Inverted index for double-byte charsets
    ::Query      RmpO    Perform scriptable queries via LWP
    ::Site       RmpO    Extract web pages via templates  
    ::Template   ampO    Template extraction and generation  
    ::WebBuilder RmpO    HTML rendering for BBS-based services     

=head1 DESCRIPTION

The OurNet:* modules are interfaces to BBS-based groupware projects,
whose platform was used in Hong Kong, China and Taiwan by est. 1 
million users. Used collaboratively, they glue BBSes together to form
a distributed service network, called 'OurNet'.                  

Please refer to each individual modules' documentation for usage
information. 

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

=cut
