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
