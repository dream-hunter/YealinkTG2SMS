#!/usr/bin/env perl

use strict;
use warnings;
use IO::Socket::INET;
use IO::Socket::Timeout;
use Data::Dumper;

my ($dstnum, $smstext) = @ARGV;
my $portnum = 2;
my $host = '10.37.224.60';
my $port = 5038;
my $username = 'apiuser';
my $password = 'apipass';
my @result = [];
print "\nBegin Program.\n";

# Создаём сокет для подключения
my $socket = IO::Socket::INET->new(
    PeerHost => $host,
    PeerPort => $port,
    Proto => 'tcp',
    Timeout => 2
) or die "Не удалось подключиться к серверу: $!\n";
IO::Socket::Timeout->enable_timeouts_on($socket);
$socket->read_timeout(0.5);
$socket->write_timeout(0.5);

print "Socket created. Reading data...\n\n";

$socket->autoflush(1);

@result = readData($socket);

if (@result && pop(@result) eq 'Asterisk Call Manager/1.1') {
    sendData("Action: Login\r\nUsername: $username\r\nSecret: $password\r\n\r\n");
} else {
    exit 1;
}

@result = readData($socket);

if (@result && pop(@result) eq 'Message: Authentication accepted') {
    if (defined $dstnum && defined $smstext) {
        my $id = time();
        sendData("Action: smscommand\r\ncommand: gsm send sms $portnum $dstnum \"$smstext\" $id\r\n\r\n");
    } else {
        sendData("Action: smscommand\r\ncommand: gsm show spans\r\n\r\n");
    }
} else {
    exit 1;
}
@result = readData($socket);


# Закрываем сокет
$socket->close();

sub readData {
    my $socket = $_[0];
    my @result = [];
    my $response = $socket->getline;
    while ($response) {
        if (defined $response && $response ne '') {
            $response =~ s/[\r\n]+//g;
            print "$response\n";
            if ($response ne '') {
                push (@result, $response);
            }
        }
        $response = $socket->getline;
    }
    return @result;
}

sub sendData {
    my $request = $_[0];
    print $socket $request;
    print $request;

    return undef;
}