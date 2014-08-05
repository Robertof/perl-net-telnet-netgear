#!/usr/bin/env perl
package Netgear::Telnet 0.01;
use feature 'say';
use strict;
use warnings;
use Carp;
use IO::Select;
use IO::Socket::INET;
use Netgear::Telnet::Packet;
use Time::HiRes 'sleep';

sub new
{
    my ($self, %opts) = @_;
    croak "incorrect parameters: missing packet or/and IP\n"
        unless exists $opts{packet} and exists $opts{ip};
    croak "packet is not a subclass of Netgear::Telnet::Packet" 
        unless ref ($opts{packet}) =~ /^Netgear::Telnet::Packet/;
    # pre-generate the packet so for multiple calls we don't get slowed down
    $opts{packet} = $opts{packet}->get_packet();
    bless \%opts, $self;
}

sub send_commands
{
    my ($self, @commands) = @_;
    my $command = join "; ", map { ref $_ eq 'ARRAY' ? join " ", @$_ : $_ } @commands;
    my $rsock = IO::Socket::INET->new (
        PeerHost => $self->{ip},
        PeerPort => 23,
        Proto    => "tcp",
        Timeout  => 1
    ) || croak "can't connect to the router: $!\n";
    unless (IO::Select->new ($rsock)->can_read (1))
    {
        #say "dbg: sending packet";
        binmode $rsock;
        $rsock->send ($self->{packet});
        close $rsock;
        # unfortunately we need sleep() due to how slow
        # netgear routers are :(
        sleep (0.30);
        $rsock = IO::Socket::INET->new (
            PeerHost => $self->{ip},
            PeerPort => 23,
            Proto    => "tcp",
            Timeout  => 1
        ) || croak "can't re-establish a connection to the router: $!\n";
        croak "telnet packet is invalid, router didn't send anything on the ",
               "2nd connection" unless IO::Select->new ($rsock)->can_read (1);
    }
    # don't mind this, I was drunk
    my $delimiter =
        int (rand 512) .
        "-" .
        join (
            '',
            map
                [ '0' .. '9', 'A' .. 'Z', 'a' .. 'z' ]->[rand 62],
                1 .. 16
        )   .
        "-" .
        int (rand 512);
    say $rsock 'jtmpvar="Q"', '; echo "${jtmpvar}', $delimiter, '"; ',
        $command, "; exit";
    my ($buffer, $buffenab);
    # wait until the connection is closed
    while (<$rsock>) {
        if (!$buffenab && index ($_, "Q${delimiter}") == 0) {
            $buffenab = 1;
            next;
        }
        $buffer .= $_ if $buffenab;
    }
    close $rsock;
    $buffer =~ s/\r?\n$//gm if defined $buffer;
    return $buffer;
}

1;
__END__

=encoding utf8

=head1 NAME

Netgear::Telnet - easy-to-use telnet library designed for Netgear routers

=head1 SYNOPSIS

    use Netgear::Telnet;
    my $packet = Netgear::Telnet::Packet->new(mac => "AA:BB:CC:DD:EE");
    my $client = Netgear::Telnet->new(ip => "10.0.0.0", packet => $packet);
    # Some example commands (may not work on all routers)
    my $router_date = $client->send_commands("date");
    my $adsl_status = $client->send_commands([ "adslctl", "info" ]);
    my $my_identity = $client->send_commands("whoami", [ "echo", '$USER' ]);

=head1 DESCRIPTION

This module provides a really easy to use API to interact with the telnet
service on Netgear routers. Specifically, this library provides the
possibility to automatically enable the telnet service on a target router
by using a "telnet enable packet". The packet can either be user provided
or it can be generated automatically given the MAC address of the router.
More information is available on the OpenWRT wiki page:
L<http://wiki.openwrt.org/toh/netgear/telnet.console>

=head1 METHODS

=over 4

=item C<new( %options )>

Creates a new C<Netgear::Telnet> instance.

C<%options> must be populated with the following items:

=over 8

=item * C<< ip => '10.0.0.0' >>

The hostname or IP of the router.

=item * C<< packet => ... >>

The L<Netgear::Telnet::Packet> instance which is used to unlock the telnet
interface, if necessary. It B<won't> be used if the telnet interface is
already unlocked or if the unlock does not need to be performed.

=back

=item C<send_commands( 'command', [ 'cmd', 'with', 'params' ] )>

Opens a connection to the remote telnet server and sends the specified
commands. Any number of arguments (commands) may be provided, either
as string or as an array reference, where each item represents a parameter.

Note that B<no escaping is performed> on the commands. This means that if
you are dealing with any kind of untrusted (user-provided) data, you need
to escape it. Check out L<perlfunc/"quotemeta">.

=back

=head1 CAVEATS

This is a really basic library, it does not implement any specific thing
of the telnet protocol. You may even use it to just generate packets and
send the commands by yourself with another library.

Each time you invoke the C<send_commands> function a new connection is
made to the server (which, when the commands are sent and the data has
been received, is closed). Consequently, it's convenient to send all the
commands you need at once.

=head1 SEE ALSO

L<Info about telnet on Netgear routers in the OpenWRT
wiki|http://wiki.openwrt.org/toh/netgear/telnet.console>,
L<Netgear::Telnet::Packet documentation|Netgear::Telnet::Packet>
documentation on how to create packets.

=head1 AUTHOR

Roberto Frenna (robertof DOT public AT gmail DOT com)

=head1 LICENSE

Copyright (c) 2014 Roberto Frenna.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
