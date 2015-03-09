#!/usr/bin/env perl
use strict;
use warnings;
use Net::Telnet::Netgear;
use Test::More;
use subs 'setup_socket';
use constant {
    ACTION_ACCEPT_CLIENTS   => 0,
    ACTION_REQUEST_PACKET   => 1,
    ACTION_SHUTDOWN         => 2
};

# Configuration
my @packet_gen_args  = ( mac => "AABBCCDDEEFF" );
my $packet_sha1      = "bce8be8764099fbb4012acbaec12e811c0b2ba88";
my @tests            = (
    {
        protocol  => "tcp",
        send_mode => "auto"
    },
    {
        protocol  => "tcp",
        send_mode => "tcp"
    },
    {
        protocol  => "udp",
        send_mode => "auto"
    },
    {
        protocol  => "udp",
        send_mode => "udp"
    }
);

BEGIN {
    foreach (qw[Digest::SHA IO::Socket::INET threads threads::shared])
    {
        eval "use $_; 1" || plan skip_all => "$_ required for this test!";
    }
};

# Storage variables
my $tcp_client_action :shared; # boolean
my $loopback_ip = IO::Socket::INET::inet_ntoa (IO::Socket::INET::INADDR_LOOPBACK); # IP address
# setup_socket returns a port number when the argument 'port' is not specified
my $port = setup_socket proto => 'tcp', code => \&handle_tcp_connection;

# Skip everything if we can't bind to a random TCP port.
plan skip_all => $port if $port =~ /^\D+$/;
plan tests => 2 * @tests;

# Prepare to skip UDP tests if we can't receive messages on the port we got before.
my $udp_ok = setup_socket proto => 'udp', port => $port, code => \&handle_udp_messages;

# Pre-generate the packet.
my $packet = Net::Telnet::Netgear::Packet->new (@packet_gen_args)->get_packet;

foreach my $test (@tests)
{
    SKIP: {
        if ($test->{protocol} eq "udp")
        {
            # Skip UDP tests if $udp_ok isn't 1
            skip $udp_ok, 2 if $test->{protocol} eq "udp" && $udp_ok ne 1;
            # Kick incoming clients on the TCP socket (which will be closed)
            lock ($tcp_client_action);
            $tcp_client_action = ACTION_SHUTDOWN;
            # Let the TCP socket close itself
            IO::Socket::INET->new ("$loopback_ip:$port")->close;
            # Wait a few seconds just to be sure
            select undef, undef, undef, 1.5;
        }
        else
        {
            lock ($tcp_client_action);
            $tcp_client_action = ACTION_REQUEST_PACKET;
        }
        my $client = Net::Telnet::Netgear->new (
            packet_send_mode => $test->{send_mode},
            packet_content   => $packet,
            host             => $loopback_ip,
            port             => $port
        );
        isa_ok $client, 'Net::Telnet::Netgear'; # because new returns undef on failure
        is $client->getline, "OK\n", 'packet sent correctly with send_mode = ' .
            $test->{send_mode} . ' & proto = ' . $test->{protocol};
        $client->close;
    }
}

sub setup_socket
{
    my %conf = @_;
    my $sock = IO::Socket::INET->new (
        LocalAddr => $loopback_ip,
        LocalPort => $conf{port} || 0, # 0 = kernel-picked port
        Proto     => $conf{proto},
        $conf{proto} eq "tcp" ? (Listen => 1, ReuseAddr => 1) : ()
    ) || return "can't listen to INADDR_LOOPBACK: $!";
    threads->create ($conf{code}, $sock)->detach;
    exists $conf{port} ? 1 : $sock->sockport();
}

sub handle_tcp_connection
{
    my $sock = shift;
    while (my $client = $sock->accept())
    {
        lock ($tcp_client_action);
        if ($tcp_client_action == ACTION_REQUEST_PACKET)
        {
            binmode $client;
            my $buf;
            # Read 0x80 bytes (the length of a packet)
            my $r = sysread $client, $buf, 0x80;
            unless (defined $r && $r == 0x80 && packet_ok ($buf))
            {
                # Wrong packet.
                next;
            }
            $tcp_client_action = ACTION_ACCEPT_CLIENTS;
            next;
        }
        elsif ($tcp_client_action == ACTION_SHUTDOWN)
        {
            close $sock;
            return;
        }
        # $tcp_client_action == ACTION_ACCEPT_CLIENTS, reply with "OK"
        print $client "OK\n";
    }
}

sub handle_udp_messages
{
    my $sock = shift;
    my $buf;
    while ($sock->recv ($buf, 0x80, 0))
    {
        if (packet_ok ($buf))
        {
            # Re-open the TCP socket with the port defined before
            my $r = setup_socket proto => 'tcp', port => $port, code => \&handle_tcp_connection;
            return diag ("Can't re-open the TCP socket: $r") if $r ne 1;
            # Clients are now allowed
            lock ($tcp_client_action);
            $tcp_client_action = ACTION_ACCEPT_CLIENTS;
        }
    }
}

sub packet_ok
{
    Digest::SHA::sha1_hex (@_) eq $packet_sha1;
}
