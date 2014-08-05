#!/usr/bin/env perl
package Netgear::Telnet::Packet;
use strict;
use warnings;

sub new
{
    require Netgear::Telnet::Packet::Native;
    Netgear::Telnet::Packet::Native->new (splice (@_, 1));
}

sub from_string
{
    require Netgear::Telnet::Packet::String;
    Netgear::Telnet::Packet::String->new (splice (@_, 1));
}

sub from_base64
{
    require Netgear::Telnet::Packet::String;
    Netgear::Telnet::Packet::String->from_base64 (splice (@_, 1));
}

1;
__END__

=encoding utf8

=head1 NAME

Netgear::Telnet::Packet - provides "telnet enable packets" for Netgear routers

=head1 SYNOPSIS

    # If you don't need the capability of sending commands, you may
    # as well 'use Netgear::Telnet::Packet'.
    use Netgear::Telnet;
    # From string
    my $packet = Netgear::Telnet::Packet->from_string ('...');
    # From Base64-encoded string
    my $packet = Netgear::Telnet::Packet->from_base64 ('Li4u');
    # From the router MAC address
    my $packet = Netgear::Telnet::Packet->new (
        mac      => 'AA:BB:CC:DD:EE',
        username => 'Gearguy', # optional
        password => 'Geardog'  # optional
    );
    # Gets the packet as a string
    my $string = $packet->get_packet;

=head1 DESCRIPTION

This module provides the generation of "telnet enable packets" usable
on Netgear routers to unlock the telnet interface.

You can either provide a pre-generated packet from a string or you
can let the script generate it with the router MAC address.
It's also possible to specify the username and password that will
be put in the packet.

This module is just a wrapper - the code which handles the packets
is in C<Netgear::Telnet::Packet::Native> or C<Netgear::Telnet::Packet::String>,
depending on which constructor you use.

=head1 METHODS

=over 4

=item C<new( %options )>

Creates a C<Netgear::Telnet::Packet::Native> instance.

C<%options> must be populated with the following items:

=over 8

=item * C<< mac => 'AA:BB:CC:DD:EE' >>

The MAC address of your router. B<This is required.>

=item * C<< username => 'Gearguy' >>

Optional, the username which will be put in the packet.
Defaults to C<Gearguy>.

=item * C<< password => 'Geardog' >>

Optional, the password which will be put in the packet.
Defaults to C<Geardog>.

=back

=item C<from_string( STR )>

Creates a C<Netgear::Telnet::Packet::String> instance.

The string needs to be 128 bytes. However, this check is not enforced.

=item C<from_base64( BASE64_STR )>

Creates a C<Netgear::Telnet::Packet::String> instance.

The decoded string needs to be 128 bytes. However, this check is not enforced.

=item C<get_packet()>

Retrieves the generated packet (or the user provided one).

This method is implemented by the C<Netgear::Telnet::Packet::*> subclasses.

=back

=head1 SEE ALSO

L<Netgear::Telnet>,
L<Info about telnet packets on Netgear routers in the OpenWRT
wiki|http://wiki.openwrt.org/toh/netgear/telnet.console>.

=head1 AUTHOR

Roberto Frenna (robertof DOT public AT gmail DOT com)

=head1 LICENSE

Copyright (c) 2014 Roberto Frenna.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
