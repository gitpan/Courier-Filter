#
# Courier::Filter::Logger::Syslog class
#
# (C) 2004 Julian Mehnle <julian@mehnle.net>
# $Id: Syslog.pm,v 1.8 2004/10/30 01:05:29 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Filter::Logger::Syslog - A syslog logger for the Courier::Filter
framework

=cut

package Courier::Filter::Logger::Syslog;

=head1 VERSION

0.15

=cut

our $VERSION = 0.15;

=head1 SYNOPSIS

    use Courier::Filter::Logger::Syslog;

    my $logger = Courier::Filter::Logger::Syslog->new();

    # For use in an individual filter module:
    my $module = Courier::Filter::Module::My->new(
        ...
        logger => $logger,
        ...
    );

    # For use as a global Courier::Filter logger object:
    my $filter = Courier::Filter->new(
        ...
        logger => $logger,
        ...
    );

=cut

use warnings;
#use diagnostics;
use strict;

use base qw(Courier::Filter::Logger::IOHandle);

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 DESCRIPTION

This class is a syslog logger class for use with Courier::Filter and its filter
modules.  It is derived from B<Courier::Filter::Logger::IOHandle>.

=cut

sub new;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new>: RETURNS Courier::Filter::Logger::Syslog; THROWS
Courier::Error

Creates a new logger that logs messages to syslog.

=cut

sub new {
    my ($class, %options) = @_;
    
    return $class->SUPER::new(
        %options,
        timestamp   => FALSE,
        handle      => \*STDERR
    );
}

=back

=head2 Instance methods

The following instance methods are provided, as inherited from
B<Courier::Filter::Logger::IOHandle>:

=over

=item B<log_error($text)>: THROWS Perl exceptions

Logs the error message given as C<$text> (a string which may contain newlines).

=item B<log_rejected_message($message, $reason)>: THROWS Perl exceptions

Logs the B<Courier::Message> given as C<$message> as having been rejected due
to C<$reason> (a string which may contain newlines).

=back

=head1 SEE ALSO

L<Courier::Filter::Logger::IOHandle>, L<Courier::Filter::Logger>,
L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
