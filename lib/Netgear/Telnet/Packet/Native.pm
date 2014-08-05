#!/usr/bin/env perl
package Netgear::Telnet::Packet::Native;
use strict;
use warnings;
use Carp;
use Crypt::ECB;
use Digest::MD5 'md5';

our @CARP_NOT = qw ( Netgear::Telnet::Packet );

sub new
{
    my ($self, %opts) = @_;
    croak "missing parameter 'mac'"
        unless exists $opts{mac};
    $opts{username} = $opts{username} || "Gearguy";
    $opts{password} = $opts{password} || "Geardog";
    croak "mac/username/password should be less than 16 characters"
        unless length $opts{mac} < 16
        and    length $opts{username} < 16
        and    length $opts{password} < 16;
    bless \%opts, $self;
}

sub get_packet
{
    my $self = shift;
    my ($mac, $usr, $pwd) = (
        _left_justify ($self->{mac},      0x10, "\x00"),
        _left_justify ($self->{username}, 0x10, "\x00"),
        _left_justify ($self->{password}, 0x10, "\x00")
    );
    my $text    = _left_justify ($mac . $usr . $pwd, 0x70, "\x00");
    my $payload = _swap_bytes (
        _left_justify (md5 ($text) . $text, 0x80, "\x00")
    );
    my $cipher = Crypt::ECB->new;
    $cipher->padding (PADDING_NONE);
    $cipher->cipher ("Blowfish")
        || die "blowfish not available: ", $cipher->errstring;
    $cipher->key ("AMBIT_TELNET_ENABLE+" . $self->{password});
    _swap_bytes ($cipher->encrypt ($payload));
}

sub _swap_bytes
{
    pack 'V*', unpack 'N*', shift;
}

sub _left_justify
{
    my ($str, $length, $filler) = @_;
    $filler = $filler || " ";
    my $i = length $str;
    return $str if $i >= $length;
    $str .= $filler while ($i++ < $length);
    $str;
}

1;