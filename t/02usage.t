#!/usr/bin/env perl -w
use strict;
use IO::Socket::INET;
use Netgear::Telnet;
use Netgear::Telnet::Packet;
use Test::More;

# build a fake telnet server
my $fake_srv = FakeTelnetServer->new;
my $callback = sub {
    my $line = shift;
    # provide some test commands
    return join (":", map { sprintf "%02d", $_ } (localtime (time))[2, 1, 0]) . " up " . int (rand 8192) . " days"
        if $line eq "uptime";
    if ($line =~ /^(\d+)\-random\-lines$/) {
        return "User error" if $1 > 16384;
        my $str; $str .= int (rand 65536) . "\n" for 1..$1;
        return $str;
    }
    0;
};
plan skip_all => $fake_srv->errstr unless $fake_srv->listen ($callback);
plan tests => 26;

my $test_client = sub {
    my ($telnet, $do_expensive) = @_;
    is ($telnet->send_commands ([ "echo", "testity_test" ]), "testity_test", "echo 'testity_test' == testity_test");
    is ($telnet->send_commands ("iamavariable='YAY!'", [ "echo", '"var: ${iamavariable}"' ]), "var: YAY!", 'v="YAY!"; echo "var: ${v}" == var: YAY!');
    like ($telnet->send_commands ("uptime"), qr/^\d+:\d+:\d+ up \d+ days$/, 'uptime =~ ^\d+:\d+:\d+ up \d+ days$');
    is ($telnet->send_commands ("dummy"), "-fakeshell: dummy: command not found", "dummy == -fakeshell: dummy: command not found");
    is (split (/\n/, $telnet->send_commands ("128-random-lines")), 128, "lines(128-random-lines) == 128");
    is (split (/\n/, $telnet->send_commands ("16384-random-lines")), 16384, "lines(16384-random-lines) == 16384") if defined $do_expensive && $do_expensive;
};
my @config = (
    {
        method    => "from_string",
        params    => [ "xxx" ],
        dick_mode => 0,
        expensive => 1
    },
    {
        method    => "from_string",
        params    => [ "xxx" ],
        dick_mode => "b60d121b438a380c343d5ec3c2037564b82ffef3" # SHA-1 sum
    },
    {
        method    => "from_base64",
        params    => [ "eHh4" ],
        dick_mode => "b60d121b438a380c343d5ec3c2037564b82ffef3"
    },
    {
        method    => "new",
        params    => [ mac => "AA:BB:CC:DD:EE" ],
        dick_mode => "cc43400ca91ccb93553d2a05964ddbe4e2fc4cda"
    },
    {
        method    => "new",
        params    => [
            mac      => "EE:DD:CC:BB:AA",
            username => "CommonUser",
            password => "password"
        ],
        dick_mode => "72fc770162af84f944d9abf1adcd4d35662c094f"
    }
);

foreach (@config)
{
    my $method = $_->{method};
    my $packet = Netgear::Telnet::Packet->$method (@{$_->{params}});
    $fake_srv->enable_dick_mode ($_->{dick_mode}) if $_->{dick_mode};
    my $client = Netgear::Telnet->new (
        ip     => "127.0.0.1",
        packet => $packet
    );
    $test_client->($client, defined $_->{expensive});
    $fake_srv->reset_dick_mode;
}


1;
package FakeTelnetServer;
use strict;
use Digest::SHA 'sha1_hex';
use IO::Select;
use IO::Socket::INET;
use threads;
use threads::shared;
$|++;

sub new
{
    bless { packet_hash => 0, packet_accepted => 0 }, $_[0];
}

sub listen
{
    my ($self, $cmd_cb) = @_;
    share ($self->{packet_hash});
    share ($self->{packet_accepted});
    $self->{sock} = IO::Socket::INET->new (
        LocalAddr => "127.0.0.1",
        LocalPort => 23,
        Proto     => "tcp",
        Listen    => 1,
        ReuseAddr => 1
    ) || return $self->_error ("can't listen to 127.0.0.1:23: $!");
    threads->create (sub {
        my ($sock, $cmd_cb, $server) = @_;
        while (my $client = $sock->accept())
        {
            if ($server->{packet_hash} ne 0 && $server->{packet_accepted} == 0)
            {
                # be a dick
                next unless (IO::Select->new ($client)->can_read (5));
                my $buffer;
                $client->recv ($buffer, 128);
                if (sha1_hex ($buffer) ne $server->{packet_hash})
                {
                    print $client "User error!!!\n";
                    next;
                }
                ++$server->{packet_accepted};
                close $client;
                next;
            }
            print $client "# Hi, I'm a good and real Telnet server.\n";
            print $client "# Hang on, I'm creating a root shell just for you.\n";
            print $client "root\@secret:/ # ";
            my %vars;
            while (my $line = <$client>)
            {
                chomp $line;
                my @raw_commands = split /\s?;\s?/, $line;
                my @answers;
                my $wants_to_die = 0;
                print $client $line, "\n";
                foreach (@raw_commands)
                {
                    if (/^(\w+)\s*=\s*["']?(.+?)["']?$/) {
                        $vars{$1} = $2;
                    } elsif (/^echo\s*["']?(.+?)["']?\s*$/i) {
                        my $text = $1;
                        $text =~ s/\$\{?$_\}?/$vars{$_}/g foreach keys %vars;
                        push @answers, $text;
                    } elsif ($_ eq "exit") {
                        ++$wants_to_die;
                        last;
                    } else {
                        if (!(my $res = $cmd_cb->($_))) {
                            push @answers, "-fakeshell: $_: command not found";
                        } else {
                            push @answers, $res;
                        }
                    }
                }
                print $client $_, "\n" foreach @answers;
                last if $wants_to_die;
                print $client "root\@secret:/ # ";
            }
        }
        $sock->close();
    }, $self->{sock}, $cmd_cb, $self)->detach;
    1;
}

sub enable_dick_mode
{
    $_[0]->{packet_hash} = $_[1];
}

sub reset_dick_mode
{
    $_[0]->{packet_hash} = 0 if exists $_[0]->{packet_hash};
    $_[0]->{packet_accepted} = 0 if exists $_[0]->{packet_accepted};
}

sub errstr
{
    $_[0]->{errstr};
}

sub _error
{
    $_[0]->{errstr} = $_[1];
    0;
}

1;
