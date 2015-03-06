#!/usr/bin/env perl
use strict;
use warnings;
use Net::Telnet::Netgear;
use Test::More;

BEGIN { eval 'use Test::Fatal; 1' || plan skip_all => 'Test::Fatal required for this test!'; }

plan tests => 8;

like (
    exception { Net::Telnet::Netgear->new (packet_instance => 'dummy') },
    qr/packet_instance must be a Net::Telnet::Netgear::Packet instance/,
    'croak when packet_instance is invalid'
);

my $sendmode_re = qr/unknown packet_send_mode/;

like (
    exception { Net::Telnet::Netgear->new (packet_send_mode => 'dummy') },
    $sendmode_re,
    'croak when packet_send_mode is invalid (constructor)'
);

like (
    exception { Net::Telnet::Netgear->new->packet_send_mode ('dummy') },
    $sendmode_re,
    'croak when packet_send_mode is invalid (mutator)'
);

like (
    exception { Net::Telnet::Netgear::Packet->new },
    qr/Missing required parameter/,
    'croak when incorrect params are supplied to Packet->new'
);

like (
    exception { Net::Telnet::Netgear::Packet->new (mac => 'A' x 16) },
    qr/have to be shorter/,
    'croak when the fields are too long in Net::Telnet::Netgear::Packet::Native (mac)'
);

like (
    exception { Net::Telnet::Netgear::Packet->new (mac => 'x', username => 'B' x 16) },
    qr/have to be shorter/,
    'croak when the fields are too long in Net::Telnet::Netgear::Packet::Native (username)'
);

like (
    exception { Net::Telnet::Netgear::Packet->new (mac => 'x', password => 'C' x 34) },
    qr/must have a maximum length of/,
    'croak when the fields are too long in Net::Telnet::Netgear::Packet::Native (password)'
);

like (
    exception { Net::Telnet::Netgear::Packet->get_packet },
    qr/not implemented/,
    'die when get_packet is called on Net::Telnet::Netgear::Packet'
);
