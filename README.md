# Netgear::Telnet
_easy-to-use telnet library designed for Netgear routers_

This module provides a really easy to use API to interact with the telnet
service on Netgear routers. Specifically, this library provides the
possibility to automatically enable the telnet service on a target router
by using a "telnet enable packet". The packet can either be user provided
or it can be generated automatically given the MAC address of the router.
More information is available [on the OpenWRT wiki page](http://wiki.openwrt.org/toh/netgear/telnet.console).

Synopsis
-------

    use Netgear::Telnet;
    my $packet = Netgear::Telnet::Packet->new(mac => "AA:BB:CC:DD:EE");
    my $client = Netgear::Telnet->new(ip => "10.0.0.0", packet => $packet);
    # Some example commands (may not work on all routers)
    my $router_date = $client->send_commands("date");
    my $adsl_status = $client->send_commands([ "adslctl", "info" ]);
    my $my_identity = $client->send_commands("whoami", [ "echo", '$USER' ]);

Methods
-------

- `new( %options )`

    Creates a new `Netgear::Telnet` instance.

    `%options` must be populated with the following items:

    - `ip => '10.0.0.0'`

        The hostname or IP of the router.

    - `packet => ...`

        The [Netgear::Telnet::Packet](lib/Netgear/Telnet/Packet.pod) instance which is used to unlock the telnet
        interface, if necessary. It **won't** be used if the telnet interface is
        already unlocked or if the unlock does not need to be performed.

- `send_commands( 'command', [ 'cmd', 'with', 'params' ] )`

    Opens a connection to the remote telnet server and sends the specified
    commands. Any number of arguments (commands) may be provided, either
    as string or as an array reference, where each item represents a parameter.

    Note that **no escaping is performed** on the commands. This means that if
    you are dealing with any kind of untrusted (user-provided) data, you need
    to escape it. Check out ["quotemeta" in perlfunc](https://metacpan.org/pod/perlfunc#quotemeta).

Caveats
------

This is a really basic library, it does not implement any specific thing
of the telnet protocol. You may even use it to just generate packets and
send the commands by yourself with another library.

Each time you invoke the `send_commands` function a new connection is
made to the server (which, when the commands are sent and the data has
been received, is closed). Consequently, it's convenient to send all the
commands you need at once.

See also
--------

[Info about telnet on Netgear routers in the OpenWRT wiki](http://wiki.openwrt.org/toh/netgear/telnet.console),
[Netgear::Telnet::Packet documentation](lib/Netgear/Telnet/Packet.pod) on how to create packets.

Author
------

Roberto Frenna (robertof DOT public AT gmail DOT com)

License
-------

Copyright (c) 2014 Roberto Frenna.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
