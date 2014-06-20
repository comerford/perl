#!/usr/bin/perl -w


# This is a simple Perl Script to ping and AJP server and print the response
# written as a sub-routine for easy embedding elsewhere
#

# Author: Adam Comerford (http://comerford.cc)
#
# For more information see: The Apache Tomcat Connector - AJP Protocol Reference - http://tomcat.apache.org/connectors-doc/ajp/ajpv13a.html

# Acknowledgements:
# The hex values are based on the information from http://tomcat.apache.org/connectors-doc/ajp/ajpv13a.html#Packet%20Headers
# Actual pack code to create the hex packets is from http://it-nonwhizzos.blogspot.com/2009/05/ajp-ping-in-perl.html

use strict;
use IO::Socket::INET;

my $result = ajp_probe($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3]);
print "$result \n";

sub ajp_probe {

        # flush after every write
        $| = 1;

        ## There must be at least 3 arguments to this function.
        ##      1. First argument is the IP that has to be probed.
        ##      2. Second argument is the port to connect to.
        ##      3. Timeout

        if(scalar(@ARGV) < 3)
        {   
                return "Insufficient number of arguments, there should be three, something like:\n\nperl ajp.pl 192.168.1.1 8009 3\n";
    
        }   

        my $server_ip = $ARGV[0];
        my $port = $ARGV[1];
        my $timeout = $ARGV[2];
    
        my $errcode = 0;
    
        my $sendhex = pack 'C5' # Format template (pack the next 5 unsigned char (octet) values)
            , 0x12, 0x34        # Magic number for server->container packets.
            , 0x00, 0x01        # 2 byte int length of payload.
            , 0x0A              # Type of packet. 10 = CPing.
        ;   

        my $recvhex = pack 'C5'     # Format template.
            , 0x41, 0x42            # Magic number for container->server packets.
            , 0x00, 0x01            # 2 byte int length of payload.
            , 0x09                  # Type of packet. 9 = CPong reply.
        ;   
my $socket = new IO::Socket::INET (
        PeerHost => $server_ip,
        PeerPort => $port,
        Proto => 'tcp',
        Timeout => $timeout,
        ) or die "ERROR in Socket Creation : $!\n";

        $socket->send($sendhex);

        my $read;

        $socket->recv($read, 1024);

        ## Probe completed.
        $socket->shutdown(2);

        if ($recvhex eq $read) {
                # a successful probe should return a line like this:
                # success - AB
                # (from a test Jetty instance) 
                return "success - $read";
        } else {
                return "Mismatch on Response - malformed PONG or other error";
        }

}
