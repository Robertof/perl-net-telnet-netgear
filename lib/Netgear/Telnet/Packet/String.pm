#!/usr/bin/env perl
package Netgear::Telnet::Packet::String;
use strict;
use warnings;
use Carp;
use MIME::Base64;

our @CARP_NOT = qw ( Netgear::Telnet::Packet );

sub new
{
    my ($self, $content, $is_base64) = @_;
    croak "Did you forget something? (no packet)" unless defined $content;
    bless { is_base64 => defined $is_base64, content => $content }, $self;
}

sub from_base64
{
    shift->new (shift, 1);
}

sub get_packet
{
    $_[0]->{is_base64} ? decode_base64 ($_[0]->{content}) : $_[0]->{content};
}

1;
