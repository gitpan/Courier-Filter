#
# Courier::Filter::Module::DNSBL class
#
# (C) 2003-2005 Julian Mehnle <julian@mehnle.net>
# $Id: DNSBL.pm 199 2005-11-10 22:16:37Z julian $
#
##############################################################################

=head1 NAME

Courier::Filter::Module::DNSBL - A DNS black-list filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::DNSBL;

=head1 VERSION

0.17

=cut

our $VERSION = '0.17';

=head1 SYNOPSIS

    use Courier::Filter::Module::DNSBL;
    
    my $module = Courier::Filter::Module::DNSBL->new(
        zones       => \@dns_zones,
        
        logger      => $logger,
        inverse     => 0,
        trusting    => 0,
        testing     => 0,
        debugging   => 0
    );
    
    my $filter = Courier::Filter->new(
        ...
        modules     => [ $module ],
        ...
    );

=cut

use warnings;
use strict;

use base qw(Courier::Filter::Module);

use IO::File;
use Net::RBLClient;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

my $OCTECT_DECIMAL  = qr/\d|\d\d|[01]\d\d|2[0-4]\d|25[0-5]/;
my $IPV4_ADDRESS    = qr/$OCTECT_DECIMAL(?:\.$OCTECT_DECIMAL){3}/;

# Interface:
##############################################################################

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if the sending machine's IP address (currently IPv4 only) is listed by
one of the configured DNS black-lists.

=cut

sub new;

sub match;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS Courier::Filter::Module::DNSBL

Creates a new B<DNSBL> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<zones>

REQUIRED.  A reference to an array containing the DNS zone names of the
black-lists to be used.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new()"> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    my $dnsbl_client = Net::RBLClient->new(
        lists       => $options{zones},
        query_txt   => TRUE,
        max_time    => 10
    );
    
    return $class->SUPER::new(
	%options,
        dnsbl_client => $dnsbl_client
    );
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($module, $message) = @_;
    my $class = ref($module);
    
    $message->remote_host =~ /^(?:::ffff:)?($IPV4_ADDRESS)$/i
        or return; # Ignore IPv6 senders for now, as Net::RBLClient doesn't support it.
    
    my $remote_host_ipv4 = $1;
    
    my $dnsbl_client = $module->{dnsbl_client};
    
    $dnsbl_client->lookup($remote_host_ipv4);
    
    my $result;
    
    my $results = $dnsbl_client->txt_hash();
    if (keys(%$results)) {
        $result = join(
            "\n",
            map(
                sprintf("DNSBL/%s: %s", $_, $results->{$_}),
                keys(%$results)
            )
        );
    }
    
    return $result;
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
