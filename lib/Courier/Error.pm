#
# Courier::Error class
#
# (C) 2003-2004 Julian Mehnle <julian@mehnle.net>
# $Id: Error.pm,v 1.10 2004/10/22 00:27:12 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Error - A Perl exception class for Perl modules related to the Courier
MTA

=cut

package Courier::Error;

=head1 VERSION

0.14

=cut

our $VERSION = 0.14;

=head1 SYNOPSIS

=head2 Exception handling

    use Error qw(:try);
    use Courier::Error;
    
    try {
        ...
        throw Courier::Error($error_message) if $error_condition;
        ...
    }
    catch Courier::Error with {
        ...
    };
    # See "Error" for more exception handling syntax.

=head2 Deriving new exception classes

    package Courier::Error::My;
    use base qw(Courier::Error);

=head1 DESCRIPTION

This class is a simple exception class for Perl modules related to the Courier
MTA.  See L<Error> for detailed instructions on how to use it.

=cut

use warnings;
#use diagnostics;
use strict;

use Error;

use base qw(Error::Simple);

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SEE ALSO

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
