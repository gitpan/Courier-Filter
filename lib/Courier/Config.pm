#
# Courier::Config class
#
# (C) 2003-2004 Julian Mehnle <julian@mehnle.net>
#
# $Id: Config.pm,v 1.6 2004/02/17 13:28:54 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Config - A Perl class providing configuration information for Perl
modules related to the Courier MTA

=cut

package Courier::Config;

=head1 VERSION

0.1

=cut

our $VERSION = 0.1;

=head1 SYNOPSIS

    use Courier::Config;
    
    # Courier base configuration:
    Courier::Config::COURIER_CONFIG_DIR;
    Courier::Config::COURIER_RUNTIME_DIR;
    
    # Courier::Filter configuration:
    Courier::Config::COURIER_FILTER_CONF;

=head1 DESCRIPTION

This class provides configuration information for Perl modules related to the
Courier MTA, e.g. installation specific file system paths.

=cut

use warnings;
#use diagnostics;
use strict;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Declarations:
##############################################################################

=head2 Courier base configuration

The following Courier base configuration information is provided:

=over 4

=item B<COURIER_CONFIG_DIR>

The base configuration directory of Courier.

=cut

use constant COURIER_CONFIG_DIR     => '/etc/courier';

=item B<COURIER_RUNTIME_DIR>

The directory where Courier keeps the message queue (C<msgq>, C<msgs>, C<tmp>)
and courierfilter sockets (C<filters>, C<allfilters>).

=cut

use constant COURIER_RUNTIME_DIR    => '/var/lib/courier';  # Normally '/var/run/courier'.

=back

=head2 Courier::Filter configuration

The following Courier::Filter configuration information is provided:

=over 4

=item B<COURIER_FILTER_CONF>

The absolute file name of the Courier::Filter pureperlfilter configuration
file.

=cut

use constant COURIER_FILTER_CONF    => COURIER_CONFIG_DIR . '/filters/pureperlfilter.conf';

=back

=head1 SEE ALSO

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
