#
# Courier::Filter::Module::SPFout class
#
# (C) 2005 Julian Mehnle <julian@mehnle.net>
# $Id: SPFout.pm,v 1.3 2005/01/17 18:57:46 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Filter::Module::SPFout - An outbound SPF filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::SPFout;

=head1 VERSION

0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

    use Courier::Filter::Module::SPFout;

    my $module = Courier::Filter::Module::SPFout->new(
        match_on            => \@match_on_result_codes,
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
use strict;

use base qw(Courier::Filter::Module);

use Error qw(:try);

use Mail::SPF::Query 1.991;
use Net::DNS qw();
use Net::Address::IPv4::Local;

use Courier::Error;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant DEFAULT_MATCH_ON   => ['fail', 'softfail', 'unknown', 'error'];

my $OCTECT_DECIMAL  = qr/\d|\d\d|[01]\d\d|2[0-4]\d|25[0-5]/;
my $IPV4_ADDRESS    = qr/$OCTECT_DECIMAL(?:\.$OCTECT_DECIMAL){3}/;

# Interface:
##############################################################################

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if the receiving (local) machine's IP address (currently IPv4 only) is
I<not> authorized to send mail from the envelope sender's (MAIL FROM) domain
according to that domain's DNS SPF (Sender Policy Framework) record.  This is
I<outbound> SPF checking.

The point of inbound SPF checking is for message submission agents (MSAs,
smarthosts) to protect I<others> against forged envelope sender addresses in
messages submitted by the MSA's users.

=cut

sub new;

sub match;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS Courier::Filter::Module::SPFout

Creates a new B<SPFout> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<trusting> (DISABLED)

Since I<outbound> SPF checking, as opposed to I<inbound> SPF checking, is
applied to trusted (authenticated) messages only, this module cannot be set to
be B<trusting>.  Also see the description of the C<trusted> property in
L<Courier::Message>.  Locked to B<false>.

=item B<match_on>

A reference to an array containing the set of SPF result codes which should
cause the filter module to match a message.  Possible result codes are C<pass>,
C<neutral>, C<softfail>, C<fail>, C<none>, C<unknown>, and C<error>.  See the
SPF specification for details on the meaning of those.  Even if C<error> is
listed, an C<error> result will by definition never cause a I<permanent>
rejection, but only a I<temporary> one.  Defaults to B<['fail', 'softfail',
'unknown', 'error']>, which complies with the long-term vision of SPF.  For the
time being, you should probably override this to B<['fail', 'unknown',
'error']>.

=item B<default_response>

A string that is to be returned as the match result in case of a match, that is
when a message fails the SPF check, if the (alleged) envelope sender domain
does not provide an explicit response.  SPF macro substitution is performed on
the default response, just like on responses provided by domain owners.  If
B<undef>, the hard-coded default response of Mail::SPF::Query will be used; see
L<Mail::SPF::Query/"new"> for the definition of that.  Defaults to B<undef>.

=item B<force_response>

Instead of merely specifying a default response for cases where the sender
domain does not provide an explicit response, you can also specify a response
to be used in I<all> cases, even if the sender domain does provide one.  This
may be useful if you do not want to confuse your own users with I<3rd-party>
provided explanations when in fact they are only dealing with I<your> server
not wanting to relay their messages.  Defaults to B<undef>.

=back

All options of the B<Courier::Filter::Module> constructor (except the
B<trusting> option) are also supported.  Please see
L<Courier::Filter::Module/"new"> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    $options{trusting} = FALSE;
    $options{match_on} ||= DEFAULT_MATCH_ON;
    
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
    
    return if not $message->trusted;
        # This filter module applies to trusted (authenticated) messages only.
    #STDERR->print("SPFout: hello. message is trusted.\n");
    
    $message->remote_host =~ /^::ffff:($IPV4_ADDRESS)$/
        or return;  # Ignore IPv6 senders for now, as M:S:Q doesn't support it.
    #STDERR->print("SPFout: sender has IPv4 address\n");
    
    my $remote_host_ipv4 = $1;
    
    my ($sender_domain) = $message->sender =~ /\@([^@]*)$/;
    $sender_domain ||= $message->remote_host_helo;
    #STDERR->print("SPFout: sender domain is \"$sender_domain\"\n");
    
    my $outbound_address_ipv4;
    try {
        # Just try the domain's first MX as the remote host:
        my ($mx) = Net::DNS::mx($sender_domain);
        #STDERR->print("SPFout: sender MX is \"", $mx->exchange, "\"\n");
        # Discover local outbound IP address:
        $outbound_address_ipv4 =
            defined($mx) ?
                Net::Address::IPv4::Local->connected_to($mx->exchange)
            :   Net::Address::IPv4::Local->public;
    };
    throw Courier::Error('Could not determine local outbound IP address')
        if not defined($outbound_address_ipv4);
    #STDERR->print("SPFout: local outbound IP address is \"$outbound_address_ipv4\"\n");
    
    my $spf_query = Mail::SPF::Query->new(
        ip          => $outbound_address_ipv4,
        helo        => $message->remote_host_helo,
        sender      => $message->sender,
        default_explanation
                    => $module->{default_response}
    );
    
    my ($result_code, $response, $header_comment, $spf_record) = $spf_query->result();
    $result_code = 'unknown' if $result_code =~ /^unknown/;
    $response =~ s/^SPF: //;
    #STDERR->print("SPFout: SPF result is \"$result_code\"\n");
    
    my %match_on;
    @match_on{ @{$module->{match_on}} } = ();
    
    if (exists($match_on{$result_code})) {
        $response = $spf_query->macro_substitute($module->{force_response})
            if defined($module->{force_response});
        return "SPFout: $response", ($result_code eq 'error' ? 451 : ())
    }
    else {
        return undef;
    }
}

=head1 SEE ALSO

L<Courier::Filter::Module::SPF>, L<Courier::Filter::Module>,
L<Courier::Filter::Overview>, L<Mail::SPF::Query>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 REFERENCES

=over

=item B<SPF website> (Sender Policy Framework)

L<http://spf.pobox.com>

=item B<SPF specification>

L<http://spf.pobox.com/spf-draft-200406.txt>

=back

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
