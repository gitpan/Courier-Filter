#
# Courier::Filter::Logger abstract base class
#
# (C) 2003-2005 Julian Mehnle <julian@mehnle.net>
# $Id: Logger.pm 199 2005-11-10 22:16:37Z julian $
#
##############################################################################

=head1 NAME

Courier::Filter::Logger - An abstract Perl base class for loggers used by the
Courier::Filter framework

=cut

package Courier::Filter::Logger;

=head1 VERSION

0.17

=cut

our $VERSION = '0.17';

=head1 SYNOPSIS

=head2 Courier::Filter logging

    use Courier::Filter::Logger::My;  # Need to use a non-abstract sub-class.
    
    my $logger = Courier::Filter::Logger::My->new(%options);
    
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

=head2 Deriving new logger classes

    package Courier::Filter::Logger::My;
    use base qw(Courier::Filter::Logger);

=cut

use warnings;
use strict;

use Error qw(:try);

use Courier::Error;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 DESCRIPTION

Sub-classes of B<Courier::Filter::Logger> are used by the B<Courier::Filter>
mail filtering framework and its filter modules for the logging of errors and
message rejections to arbitrary targets, like file handles or databases.

When overriding a method in a derived class, do not forget calling the
inherited method from your overridden method.

=cut

sub new;
sub destroy;
sub log_error;
sub log_rejected_message;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided and may be overridden:

=over

=item B<new(%options)>: RETURNS Courier::Filter::Logger (or derivative)

Creates a new logger using the %options given as a list of key/value pairs.
Initializes the logger, by creating/opening I/O handles, connecting to
databases, etc..

C<Courier::Filter::Logger::new()> creates a hashref as an object of the invoked
class, and stores the %options in it, but does nothing else.

=cut

sub new {
    my ($class, %options) = @_;
    $class ne __PACKAGE__
        or  throw Courier::Error('Unable to instantiate abstract ' . __PACKAGE__ . ' class');
    my $logger = { %options };
    return bless($logger, $class);
}

=back

=head2 Destructor

The following destructor is provided and may be overridden:

=over

=item B<destroy>

Uninitializes the logger, by closing I/O handles, disconnecting from databases,
etc..

C<Courier::Filter::Logger::destroy()> does nothing.

=cut

sub destroy {
    my ($object) = @_;
    return;
}

=back

=head2 Instance methods

The following instance methods are provided and may be overridden:

=over

=item B<log_error($text)>

Logs the error message given as $text (a string which may contain newlines).

C<Courier::Filter::Logger::log_error()> does nothing and should be overridden.

=cut

sub log_error {
    my ($logger, $text) = @_;
    return;
}

=item B<log_rejected_message($message, $reason)>

Logs the B<Courier::Message> given as $message as having been rejected due to
$reason (a string which may contain newlines).

C<Courier::Filter::Logger::log_rejected_message()> does nothing and should be
overridden.

=cut

sub log_rejected_message {
    my ($object, $message, $reason) = @_;
    return;
}

=back

=cut

no warnings;
*DESTROY = \&destroy;

=head1 SEE ALSO

L<Courier::Filter>, L<Courier::Filter::Module>.

For a list of prepared loggers that come with Courier::Filter, see
L<Courier::Filter::Overview/"Bundled Courier::Filter loggers">.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
