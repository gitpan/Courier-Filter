#
# Courier::Filter::Module::MIMEParts class
#
# (C) 2003-2004 Julian Mehnle <julian@mehnle.net>
# $Id: MIMEParts.pm,v 1.13 2004/10/22 00:27:12 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Filter::Module::MIMEParts - A message (MIME multipart and ZIP archive)
parts filter module for the Courier::Filter framework

=cut

package Courier::Filter::Module::MIMEParts;

=head1 VERSION

0.14

=cut

our $VERSION = 0.14;

use warnings;
use strict;

use base qw(Courier::Filter::Module::Parts);

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 DESCRIPTION

As of Courier::Filter 0.13, the B<MIMEParts> filter module is I<deprecated> in
favor of the new B<Parts> filter module, which is compatible but a lot more
powerful.  The B<MIMEParts> module will be removed in Courier::Filter 0.20.
You can still instantiate B<MIMEParts> modules in your config file for now, but
what will be created is really nothing more than B<Parts> modules.  See
L<Courier::Filter::Module::Parts> for the interface description.

=cut

=head1 SEE ALSO

L<Courier::Filter::Module::Parts>, L<Courier::Filter::Module>,
L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
