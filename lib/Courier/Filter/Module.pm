#
# Courier::Filter::Module abstract base class
#
# (C) 2003-2004 Julian Mehnle <julian@mehnle.net>
# $Id: Module.pm,v 1.10 2004/10/04 21:04:49 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Filter::Module - An abstract Perl base class for filter modules used
by the Courier::Filter framework

=cut

package Courier::Filter::Module;

=head1 VERSION

0.13

=cut

our $VERSION = 0.13;

=head1 SYNOPSIS

=head2 Courier::Filter message filtering

    use Courier::Filter::Module::My;  # Need to use a non-abstract sub-class.
    
    my $module = Courier::Filter::Module::My->new(
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

=head2 Deriving new filter module classes

    package Courier::Filter::Module::My;
    use base qw(Courier::Filter::Module);

=cut

use warnings;
#use diagnostics;
use strict;

use Error qw(:try);

use Courier::Error;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 DESCRIPTION

Sub-classes of B<Courier::Filter::Module> are used by the B<Courier::Filter>
mail filtering framework to determine the acceptability of messages.  See
L<Courier::Filter::Overview> for an overview of how filter modules are used and
for how to write them.

When overriding a method in a derived class, do not forget calling the
inherited method from your overridden method.

=cut

# Actors:
########################################

sub new;
sub consider;
sub match;

# Accessors:
########################################

sub logger;
sub inverse;
sub trusting;
sub testing;
sub debugging;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided and may be overridden:

=over

=item B<new(%options)>: RETURNS Courier::Filter::Module (or derivative)

Creates a new filter module using the %options.  Initializes the filter module,
by opening I/O handles, connecting to databases, creating temporary files,
initializing parser libraries, etc..

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<logger>

A B<Courier::Filter::Logger> object that will be used for logging message
rejections and error messages caused by this individual filter module.  If no
logger is specified, Courier::Filter's global logger will be used.

=item B<inverse>

A boolean value controlling whether the filter module should operate with
inverse polarity (B<true>) as opposed to normal polarity (B<false>).  Under
inverse polarity, the result of the C<match> method is negated by the
C<consider> method before returning it.  For details on how Courier::Filter
translates I<match results> into I<acceptability results>, see
L<Courier::Filter::Overview/"How Courier::Filter modules work">.  Defaults to
B<false>.

=item B<trusting>

A boolean value controlling whether the filter module should I<not> be applied
to trusted messages.  For details on how the authenticated status is
determined, see the description of the C<trusted> property in
L<Courier::Message>.  In most configurations, this option can be used to
white-list so-called I<outbound> messages.  Defaults to B<false>.

=item B<testing>

A boolean value controlling whether the filter module should run in testing
mode.  In testing mode, planned message rejections will be logged as usual, but
no messages will actually be rejected.  Defaults to B<false>.

=item B<debugging>

A boolean value controlling whether the filter module should log extra
debugging information.  Defaults to B<false>.

=back

Derived classes may support additional options.

C<Courier::Filter::Module::new()> creates a hashref as an object of the invoked
class, and stores the %options in it, but does nothing else.

=cut

sub new {
    my ($class, %options) = @_;
    $class ne __PACKAGE__
        or  throw Courier::Error('Unable to instantiate abstract ' . __PACKAGE__ . ' class');
    my $module = { %options };
    return bless($module, $class);
}

=back

=head2 Destructor

The following destructor is provided and may be overridden:

=over

=item B<destroy>

Uninitializes the filter module, by closing I/O handles, disconnecting from
databases, deleting temporary files, uninitializing parser libraries, etc..

C<Courier::Filter::Module::destroy()> does nothing.

=cut

sub destroy {
    my ($object) = @_;
    return;
}

=back

=head2 Instance methods

The following instance methods are provided and may be overridden:

=over

=item B<consider($message)>: RETURNS SCALAR, [SCALAR]; THROWS Perl exceptions

Calls the C<match> method, passing it the $message object.  Returns the result
of C<match>, negating it beforehand if the filter module has inverse polarity.
There is usually no need at all to override this method.

=cut

sub consider {
    my ($module, $message) = @_;
    my ($result, @code) = $module->match($message);
    ($result, @code) = ($result ? '' : undef)
        if $module->inverse;
    return ($result, @code);
}

=item B<match($message)>: RETURNS SCALAR, [SCALAR]; THROWS Perl exceptions

Examines the B<Courier::Message> object given as $message.  Returns a so-called
I<match result> consisting of an SMTP status response I<text>, and an optional
numerical SMTP status response I<code>.  For details about how I<match results>
are used by Courier::Filter, see L<Courier::Filter::Overview/"How
Courier::Filter modules work"> and L<Courier::Filter::Overview/"Writing
Courier::Filter modules">.

C<Courier::Filter::Module::match()> does nothing and returns B<undef>.

=cut

sub match {
    my ($module, $message) = @_;
    return undef;
}

=item B<logger>: RETURNS Courier::Filter::Logger

=item B<logger($logger)>: RETURNS Courier::Filter::Logger

If C<$logger> is specified, installs a new logger for this individual filter
module.  Returns the current (new) logger.

=cut

sub logger {
    my ($module, @logger) = @_;
    $module->{logger} = $logger[0]
        if @logger;
    return $module->{logger};
}

=item B<inverse>: RETURNS boolean

Returns a boolean value indicating whether the filter module is operating with
inverse polarity, as set through the constructor's C<inverse> option.

=cut

sub inverse {
    my ($module) = @_;
    # Read-only!
    return ($module->{inverse});
}

=item B<trusting>: RETURNS boolean

Returns a boolean value indicating whether the filter module does I<not> apply
to trusted messages, as set through the constructor's C<trusting> option.

=cut

sub trusting {
    my ($module) = @_;
    # Read-only!
    return $module->{trusting};
}

=item B<testing>: RETURNS boolean

Returns a boolean value indicating whether the filter module is in testing
mode, as set through the constructor's C<testing> option.

=cut

sub testing {
    my ($module) = @_;
    # Read-only!
    return $module->{testing};
}

=item B<debugging>: RETURNS boolean

=item B<debugging($debugging)>: RETURNS boolean

If C<$debugging> is specified, sets the debugging mode for this individual
filter module.  Returns the current (new) debugging mode.

=cut

sub debugging {
    my ($module, @debugging) = @_;
    $module->{debugging} = $debugging[0]
        if @debugging;
    return $module->{debugging};
}

=back

=cut

no warnings;
*DESTROY = \&destroy;

=head1 SEE ALSO

L<Courier::Filter>, L<Courier::Filter::Module>.

For a list of prepared loggers that come with Courier::Filter, see
L<Courier::Filter::Overview/"Bundled Courier::Filter loggers">.

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
