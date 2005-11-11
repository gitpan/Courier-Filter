#
# Courier::Filter::Module::SpamAssassin class
#
# (C) 2005 Julian Mehnle <julian@mehnle.net>
# $Id: SpamAssassin.pm 199 2005-11-10 22:16:37Z julian $
#
##############################################################################

=head1 NAME

Courier::Filter::Module::SpamAssassin - A SpamAssassin message filter module
for the Courier::Filter framework

=cut

package Courier::Filter::Module::SpamAssassin;

=head1 VERSION

0.17

=cut

our $VERSION = '0.17';

=head1 SYNOPSIS

    use Courier::Filter::Module::SpamAssassin;

    my $module = Courier::Filter::Module::SpamAssassin->new(
        sa_options  => {
            # Mail::SpamAssassin options, e.g.:
            site_rules_filename => '/etc/spamassassin/courier-filter.cf'
        },
        
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

use Mail::SpamAssassin;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if its SpamAssassin spam score exceeds the configured threshold.

=cut

sub new;

sub match;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS Courier::Filter::Module::SpamAssassin

Creates a new B<SpamAssassin> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<sa_options>

A hashref specifying options for L<Mail::SpamAssassin>.  For example, a
Courier::Filer-specific rules file could be specified as the
C<site_rules_filename> option, as shown in the L</"SYNOPSIS">.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new"> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    my $spamassassin = Mail::SpamAssassin->new( $options{sa_options} );
    $spamassassin->compile_now();
    
    my $module = $class->SUPER::new(
        %options,
        spamassassin    => $spamassassin
    );
    
    return $module;
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($module, $message) = @_;
    my $class = ref($module);
    
    my $spamassassin    = $module->{spamassassin};
    my $sa_message      = $spamassassin->parse($message->text);
    my $status          = $spamassassin->check($sa_message);
    
    my $is_spam         = $status->is_spam;
    my $score           = $status->get_score;
    my $tests_hit       = $status->get_names_of_tests_hit;
    
    $status->finish();
    
    return 'SpamAssassin: Message looks like spam (score: ' . $score . '; ' . $tests_hit . ')'
        if $is_spam;
    
    return undef;
        # otherwise.
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
