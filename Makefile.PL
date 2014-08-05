#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
    AUTHOR           => [ 'Roberto Frenna <robertof.public@gmail.com>' ],
    NAME             => 'Netgear::Telnet',
    VERSION_FROM     => 'lib/Netgear/Telnet.pm',
    ABSTRACT         => 'Easy to use telnet library designed for Netgear routers.',
    MIN_PERL_VERSION => '5.01',
    PREREQ_PM        => {
        "Carp"             => 0,
        "Crypt::ECB"       => 0,
        "Crypt::Blowfish"  => 0,
        "Digest::MD5"      => 0,
        "IO::Select"       => 0,
        "IO::Socket::INET" => 0,
        "MIME::Base64"     => 0,
        "Time::HiRes"      => 0
    },
    TEST_REQUIRES    => {
        "Digest::SHA"      => 0,
        "Test::More"       => 0,
        "threads"          => 0,
        "threads::shared"  => 0
    }
);
