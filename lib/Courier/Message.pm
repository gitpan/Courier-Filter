#
# Courier::Message class
#
# (C) 2003-2004 Julian Mehnle <julian@mehnle.net>
# $Id: Message.pm,v 1.15 2004/10/22 00:27:12 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Message - A Perl class implementing an interface to a mail message in
the Courier MTA's message queue.

=cut

package Courier::Message;

=head1 VERSION

0.14

=cut

our $VERSION = 0.14;

use v5.8;

use warnings;
#use diagnostics;
use strict;

use overload
    '""' => \&text;

use Encode;
use IO::File;
#use MIME::Words::Better;

use Error qw(:try);

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant FALLBACK_8BIT_CHAR_ENCODING => 'windows-1252';

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Courier::Message;
    
    my $message = Courier::Message->new(
        file_name           => $message_file_name,
        control_file_names  => \@control_file_names,
    );
    
    # File names:
    my $message_file_name   = $message->file_name;
    my @control_file_names  = $message->control_file_names;
    
    # Message data properties:
    my $raw_message_text    = $message->text;
    my $header_hash         = $message->header;
    my $header_field        = $message->header($field);
    my $raw_body            = $message->body;
    
    # Control properties:
    my $control_hash        = $message->control;
    my $is_authenticated    = $message->authenticated;
    my $is_trusted          = $message->trusted;
    my $sender              = $message->sender;
    my @recipients          = $message->recipients;
    my $remote_host         = $message->remote_host;
    my $remote_host_name    = $message->remote_host_name;

=head1 DESCRIPTION

B<Courier::Message> encapsulates a mail message that is stored in the Courier
MTA's message queue, including the belonging control file(s), and provides an
easy to use, read-only interface through its message data and control
properties.  For light-weight calling of library functions or external
commands, the message and control file names may be retrieved without causing
the files to be parsed by B<Courier::Message>.

=cut

# Actors:
########################################

sub new;

# Accessors:
########################################

# File names:

sub file_name;
sub control_file_names;

# Message data properties:

sub text;
sub parse;
sub header;
sub body;

# Control Properties:

sub control;
sub authenticated;
sub trusted;
#sub relay_authorized;
#sub trusted_source;
sub sender;
sub recipients;
sub remote_host;
sub remote_host_name;

# Commonly Needed Header Fields:

sub subject;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS Courier::Message

Creates a new C<Courier::Message> object from the given message file name and
zero or more control file names.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<file_name>

REQUIRED.  A scalar containing the absolute file name of the message file.

=item B<control_file_names>

REQUIRED.  An arrayref containing the absolute file name(s) of zero or more
control files belonging to the message.

=back

=cut

sub new {
    my ($class, %options) = @_;
    my $message = { %options };
    return bless($message, $class);
}

=back

=head2 Instance methods

=head3 File names

The following file name accessors are provided:

=over

=item B<file_name>: RETURNS SCALAR

Returns the absolute file name of the message file.

=cut

sub file_name {
    my ($message) = @_;
    return $message->{file_name};
}

=item B<control_file_names>: RETURNS LIST of SCALAR

Returns the absolute file names of the control files belonging to the message.

=cut

sub control_file_names {
    my ($message) = @_;
    return @{$message->{control_file_names}};
}

=back

=head3 Message data properties

=over

=item B<text>: RETURNS SCALAR; THROWS Perl exceptions

Reads the message text from the message file into memory once.  Returns the raw
message text as bytes (see L<bytes>, and L<PerlIO/"bytes">).  Throws a Perl
exception if the message file cannot be read.

=cut

sub text {
    my ($message) = @_;
    
    if (not defined($message->{text})) {
	# Read message text from file:
	local $/;
	my $message_file = IO::File->new($message->{file_name}, '<:bytes');
	$message->{text} = <$message_file>;
    }
    
    return $message->{text};
}

=begin comment

=item B<parse>: RETURNS Courier::Message

Parses the message text once by doing the following: splits the message text
into header and body; tries to interpret the header as UTF-8, falling back to
a legacy 8-bit character encoding; parses header fields from the header;
decodes any MIME encoded words in field values.  Saves the parsed header fields
and the message text in the message object.  Returns the message object.

=end comment

=cut

sub parse {
    my ($message) = @_;
    
    if (
        not defined($message->{header}) or
        not defined($message->{body})
    ) {
        # Parse header and body from message text:
	my $text = $message->text;
	my ($header_text, $body_text) = ($text =~ /^(.*?\n)\n(.*)$/s);
	
        # UTF-8-ify the header text,
        # trying to interpret it as UTF-8 first,
        # falling back to the preset 8-bit character encoding if unsuccessful:
        my $header_text_utf8 = Encode::decode_utf8($header_text);
        if (defined($header_text_utf8)) {
            $header_text = $header_text_utf8;
        }
        else {
            $header_text = Encode::decode(FALLBACK_8BIT_CHAR_ENCODING, $header_text);
        }
        
	# Unfold header lines:
	$header_text =~ s/\n(?=\s)//g;
	
	# Parse header lines into a hash of arrays:
	my $header = {};
	while ($header_text =~ /^([\w-]+):[ \t]*(.*)$/mg) {
	    my ($field, $value) = (lc($1), $2);
            try {
                $value = MIME::Words::Better::decode($value, FALLBACK_8BIT_CHAR_ENCODING);
            };
            push(@{$header->{$field}}, $value);
	}
	
	$message->{header} = $header;
        $message->{body} = $body_text;
    }
    
    return $message;
}

=item B<header>: RETURNS HASHREF

=item B<header($field)>: RETURNS LIST of SCALAR

Parses the message header once by doing the following: tries to interpret the
header as I<UTF-8>, falling back to the 8-bit legacy encoding I<Windows-1252>
(a proper superset of I<ISO-8859-1>) and decoding that to I<UTF-8>; parses
header fields from the header; and decodes any MIME encoded words in field
values.  If a (case I<in>sensitive) field name is specified, returns a list of
the values of all header fields of that name, in the order they occurred in the
message header.  If no field name is specified, returns a hashref containing
all header fields and arrayrefs of their values.

=cut

sub header {
    my ($message, @field) = @_;
    
    my $header = $message->parse()->{header};
    if (@field) {
        my $field_values = $header->{lc($field[0])} || [];
        return wantarray ? @$field_values : $field_values->[0];
    }
    else {
        return $header;
    }
}

=item B<body>: RETURNS SCALAR

Returns the raw message body as bytes (see L<bytes>, and L<PerlIO/"bytes">).

=cut

sub body {
    my ($message) = @_;
    return $message->parse()->{body};
}

=begin comment

=item B<subject>: RETURNS SCALAR

Returns the decoded value of the message's "Subject" header field.

=end comment

=cut

sub subject {
    my ($message) = @_;
    return $message->header('subject');
}

=back

=head3 Control properties

=over

=item B<control>: RETURNS HASHREF; THROWS Perl exceptions

=item B<control($field)>: RETURNS LIST of SCALAR; THROWS Perl exceptions

Reads and parses all of the message's control files once.  If a (case
sensitive) field name (i.e. record type) is specified, returns a list of the
values of all control fields of that name, in the order they occurred in the
control file(s).  If no field name is specified, returns a hashref containing
all control fields and arrayrefs of their values.  Throws a Perl exception if
any of the control files cannot be read.

=cut

sub control {
    my ($message, @field) = @_;
    
    my $control = $message->{control};
    
    if (not defined($control)) {
	# Read control files:
	foreach my $control_file_name (@{$message->{control_file_names}}) {
	    my $control_file = IO::File->new($control_file_name);
	    while (my $record = <$control_file>) {
		$record =~ /^(\w)(.*)$/;
		my ($field, $value) = ($1, $2);
                push(@{$control->{$field}}, $value);
	    }
	}
	
	# Store control information:
	$message->{control} = $control;
    }
    
    if (@field) {
        my $field_values = $control->{$field[0]} || [];
        return wantarray ? @$field_values : $field_values->[0];
    }
    else {
        return $control;
    }
}

=begin comment

=item B<control_f>

Parses the HELO string, the remote host, and the remote host name from the C<f>
control record and stores them into the message object.

=end comment

=cut

sub control_f {
    my ($message, @field) = @_;
    
    if (
        not defined($message->{remote_host}) or
        not defined($message->{remote_host_name}) or
        not defined($message->{remote_host_helo})
    ) {
        $message->control('f') =~ /^dns; (.*) \((?:(.*?) )?\[(.*?)\]\)$/;
        $message->{remote_host} = $3;
        $message->{remote_host_name} = $2;
        $message->{remote_host_helo} = $1;
    }
    
    return @field ? $message->{$field[0]} : $message->control('f');
}

=item B<authenticated>: RETURNS boolean

Returns the authentication information (guaranteed to be a B<true> value) if
the message has been submitted by an authenticated user.  Returns B<false>
otherwise.

NOTE:  The authentication status and information is currently determined and
taken from the message's first (i.e. the trustworthy) "Received" header field.
This is guaranteed to work correctly, but is not very elegant, so this is
subject to change.  As soon as Courier supports storing the authentication
status in a control file field, I<that> will be the preferred source.  This
mostly just means that the I<format> of the authentication info will probably
change in the future.

=cut

sub authenticated {
    my ($message) = @_;
    
    if (not defined($message->{authenticated})) {
        my $received = $message->header('received');
        if (
            defined($received) and
            $received =~ /^from\s+\S+\s+\(.*?\)\s+\(.*?\bauth:\s+([^,\)]*).*?\)\s+by/i
        ) {
            # Authenticated!
            $message->{authenticated} = $1 || ' ';
        }
        else {
            # Not authenticated
            $message->{authenticated} = '';
        }
    }
    
    return $message->{authenticated};
}

=item B<trusted>: RETURNS boolean

Returns a boolean value indicating whether the message is trusted.  Currently,
trusted messages are defined to be messages directly submitted by an
authenticated user.  For details on how the authenticated status is determined,
see the description of the C<authenticated> property.

=cut

sub trusted {
    my ($message) = @_;
    return $message->authenticated ? TRUE : FALSE;
}

=item B<sender>: RETURNS SCALAR

Returns the message's envelope sender (from the "MAIL FROM:" SMTP command).

=cut

sub sender {
    my ($message) = @_;
    return $message->control('s');
}

=item B<recipients>: RETURNS LIST of SCALAR

Returns all of the message's envelope recipients (from the "RCPT TO:" SMTP
commands).

=cut

sub recipients {
    my ($message) = @_;
    return $message->control('r');
}

=item B<remote_host>: RETURNS SCALAR

Returns the IP address of the SMTP client that submitted the message.

=cut

sub remote_host {
    my ($message) = @_;
    return $message->control_f('remote_host');
}

=item B<remote_host_name>: RETURNS SCALAR

Returns the host name (gained by Courier through a DNS reverse lookup) of the
SMTP client that submitted the message, if available.

=cut

sub remote_host_name {
    my ($message) = @_;
    return $message->control_f('remote_host_name');
}

=item B<remote_host_helo>: RETURNS SCALAR

Returns the HELO string that the SMTP client specified, if available.

=cut

sub remote_host_helo {
    my ($message) = @_;
    return $message->control_f('remote_host_helo');
}

=back

=head1 SEE ALSO

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut


#
# MIME::Words replacement functions
#
# (C) 2004 Julian Mehnle <julian@mehnle.net>
#
##############################################################################

package MIME::Words::Better;

use warnings;
#use diagnostics;
use strict;

use base qw(Exporter);

our @EXPORT = qw(decode_mimewords);

use Encode ();
use MIME::Base64 ();
use MIME::QuotedPrint ();

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant FALLBACK_CHAR_ENCODING => 'utf-8';

sub decode_mimewords {
    my ($text, $fallback_char_encoding) = @_;
    
    # Some MIME encoded words grammar, see RFC 2047, section 2:
    my $ENCODED_WORD = qr{
        =\? ([\w-]+) (?:\*([\w-]+))? \? ([\w]) \? ([^?]*?) \?=
        #   Charset     Language       Encoding    Chunk
    }ox;
    
    # Drop whitespace between two encoded words:
    $text =~ s/($ENCODED_WORD)\s+($ENCODED_WORD)/$1$6/;
    
    $text =~ s[$ENCODED_WORD] {
        my ($char_enc, $xfer_enc, $chunk) = ($1, lc($3), $4);
        
        $char_enc =
            Encode::resolve_alias($char_enc) ||
            $fallback_char_encoding ||
            FALLBACK_CHAR_ENCODING;

        if ($xfer_enc eq 'b') {
            # Base 64!
            $chunk = MIME::Base64::decode($chunk);
        }
        elsif ($xfer_enc eq 'q') {
            # Quoted Printable!
            $chunk =~ tr/_/\x{20}/;
            $chunk = MIME::QuotedPrint::decode($chunk);
        }
        
        Encode::decode($char_enc, $chunk);
    }eg;
    
    return $text;
}

no warnings;
*decode = \&decode_mimewords;

TRUE;

# vim:tw=79
