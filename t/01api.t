#!/usr/bin/env perl -w
use strict;
use Test::More tests => 17;

require_ok "Netgear::Telnet";
require_ok "Netgear::Telnet::Packet";
require_ok "Netgear::Telnet::Packet::Native";
require_ok "Netgear::Telnet::Packet::String";

can_ok 'Netgear::Telnet', 'new', 'send_commands';
can_ok 'Netgear::Telnet::Packet', 'new', 'from_string', 'from_base64';

my @implementations = qw ( Netgear::Telnet::Packet::Native Netgear::Telnet::Packet::String );
can_ok $_, 'new', 'get_packet' foreach @implementations;

my $packet = Netgear::Telnet::Packet->new (mac => "1234");

isa_ok $packet, 'Netgear::Telnet::Packet::Native';
can_ok $packet, '_left_justify';

$packet = Netgear::Telnet::Packet->from_string ("xxx");

isa_ok $packet, 'Netgear::Telnet::Packet::String';
can_ok $packet, 'get_packet';

is $packet->get_packet, 'xxx', 'string_packet == xxx';

$packet = Netgear::Telnet::Packet->from_base64 ("eHh4");

isa_ok $packet, 'Netgear::Telnet::Packet::String';
can_ok $packet, 'get_packet';

is $packet->get_packet, 'xxx', 'base64_packet (once decoded) == xxx';

my $class = Netgear::Telnet->new (ip => "256.256.256.256", packet => $packet);

isa_ok $class, 'Netgear::Telnet';
