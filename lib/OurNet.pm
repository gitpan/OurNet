# Placeholder module for OurNet packages

package OurNet;

$OurNet::VERSION = '1.4-alpha';

1;

=head1 NAME

OurNet::BBSAgent - Interface to BBS-based groupware platforms

=head1 SYNOPSIS

The OurNet:* modules are interfaces to BBS-based groupware projects,
whose platform was used in Hong Kong, China and Taiwan by est. 1 
million users. Used collaboratively, they glue BBSes together to form
a distributed service network, called 'OurNet'.                  

Please refer to each individual modules' documentation for usage
information. 

    ::Query      RmpO    Perform scriptable queries via LWP
    ::Site       RmpO    Extract texts with via templates  
    ::FuzzyIndex RmcO    Fuzzy match for double-byte charsets
    ::ChatBot    RmpO    Context-Free Interactive Q&A Engine 
    ::BBSAgent   RmpO    Scriptable telnet-based virtual users
    ::Cell       ampO    Interface-based RPC with Relay & Locating
    ::WebBuilder RmpO    Web Rendering for BBS-based services     
    ::Template   ampO    Template Extraction and Generation  
    ::BBS        bmpO    Component Object Model for BBS systems

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2000 by Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself for
non-commercial uses.

=cut
