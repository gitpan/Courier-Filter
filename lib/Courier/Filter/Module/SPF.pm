#
# Courier::Filter::Module::SPF class
#
# (C) 2004 Julian Mehnle <julian@mehnle.net>
# $Id: SPF.pm,v 1.11 2004/10/04 21:10:22 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Filter::Module::SPF - An SPF filter module for the Courier::Filter
framework

=cut

package Courier::Filter::Module::SPF;

=head1 VERSION

0.13

=cut

our $VERSION = 0.13;

=head1 SYNOPSIS

    use Courier::Filter::Module::SPF;

    my $module = Courier::Filter::Module::SPF->new(
        reject_on           => \@reject_on_result_codes,
        trusted_forwarders  => 0,
        fallback_guess      => 0,
        default_response    => $default_response_text,

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
#use diagnostics;
use strict;

use base qw(Courier::Filter::Module);

use Mail::SPF::Query 1.991;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant DEFAULT_REJECT_ON  => [
    'fail', 'softfail', 'none', 'unknown', 'error'
];

my $OCTECT_DECIMAL  = qr/\d|\d\d|[01]\d\d|2[0-4]\d|25[0-5]/;
my $IPV4_ADDRESS    = qr/$OCTECT_DECIMAL(?:\.$OCTECT_DECIMAL){3}/;

# Interface:
##############################################################################

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if the sending machine's IP address (currently IPv4 only) is I<not>
authorized to send mail from the envelope sender's (MAIL FROM) domain according
to that domain's DNS SPF (Sender Policy Framework) record.

=cut

sub new;

sub match;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS Courier::Filter::Module::SPF

Creates a new B<SPF> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<reject_on>

A reference to an array containing the set of SPF result codes which should
cause the filter module to match a message.  Possible result codes are C<pass>,
C<neutral>, C<softfail>, C<fail>, C<none>, C<unknown>, and C<error>.  See the
SPF specification for details on the meaning of those.  Even if C<error> is
listed, an C<error> result will by definition never cause a I<permanent>
rejection, but only a I<temporary> one.  Defaults to B<['fail', 'softfail',
'none', 'unknown', 'error']>, which complies with the long-term vision of SPF.
For the time being, you should probably override this to B<['fail', 'softfail',
'error']> or just B<['fail', 'error']>.

=item B<trusted_forwarders>

A boolean value controlling whether well-known but SPF ignorant forwarding
services, as centrally specified by the DNS zone "spf.trusted-forwarder.org",
should be generally trusted to be legitimate senders, even if they send
messages with enveloper sender domains they do not control and are not
authorized to send from.  Enabling this reduces the probability of false
positives somewhat, but increases the probability of false negatives
significantly.  Defaults to B<false>.

=item B<fallback_guess>

A boolean value controlling whether a default "best guess" SPF record should be
assumed for domains without an SPF record.  See
L<Mail::SPF::Query/"best_guess()"> for the definition of the default best guess
record.  Defaults to B<false>.

=item B<default_response>

A string that is to be returned as the match result in case of a match, that is
when a message fails the SPF check, if the (alleged) envelope sender domain
does not provide a specific response.  SPF macro substitution is performed on
the default response, just like on responses provided by domain owners.  If
B<undef>, the hard-coded default response of Mail::SPF::Query will be used; see
L<Mail::SPF::Query/"new()"> for the definition of that.  Defaults to B<undef>.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new()"> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    $options{reject_on} ||= DEFAULT_REJECT_ON;
    
    return $class->SUPER::new(%options);
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($module, $message) = @_;
    my $class = ref($module);
    
    $message->remote_host =~ /^::ffff:($IPV4_ADDRESS)$/
        or return; # Ignore IPv6 senders for now, as M:S:Q doesn't support it.
    
    my $remote_host_ipv4 = $1;
    
    my $spf_query = Mail::SPF::Query->new(
        ip          => $remote_host_ipv4,
        helo        => $message->remote_host_helo,
        sender      => $message->sender,
        trusted     => $module->{trusted_forwarders},
        guess       => $module->{fallback_guess},
        default_explanation
                    => $module->{default_response}
    );
    
    my ($result, $smtp_comment, $header_comment, $spf_record) = $spf_query->result();
    
    $result = 'unknown' if $result =~ /^unknown/;
    $smtp_comment =~ s/^SPF: //;
    
    my %reject_on;
    @reject_on{ @{$module->{reject_on}} } = ();
    
    return
#        "result=\"$result\"" . ($message->trusted ? " (but trusted)" : "") . "; " .
#        ($spf_record ? "record=\"$spf_record\"; " : '') .
        "SPF: $smtp_comment", ($result eq 'error' ? 451 : ())
        if exists($reject_on{$result});
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>, L<Mail::SPF::Query>.

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 REFERENCES

=over

=item B<SPF> (Sender Policy Framework)

L<http://spf.pobox.com>

=back

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
