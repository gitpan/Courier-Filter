#
# Courier::Filter::Module::MIMEParts class
#
# (C) 2003-2004 Julian Mehnle <julian@mehnle.net>
#
# $Id: MIMEParts.pm,v 1.6 2004/02/16 23:43:57 julian Exp $
#
# $Log: MIMEParts.pm,v $
##############################################################################

=head1 NAME

Courier::Filter::Module::MIMEParts - A MIME part filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::MIMEParts;

=head1 VERSION

0.1

=cut

our $VERSION = 0.1;

=head1 SYNOPSIS

    use Courier::Filter::Module::MIMEParts;

    my $module = Courier::Filter::Module::MIMEParts->new(
        max_size    => $max_size,
        signatures  => [
            {
                # One or more of the following options:
                mime_type   => 'text/html' || qr/html/,
                file_name   => 'file_name.ext' || qr/\.(exe|com|pif|lnk)$/,
                size        => 106496,
                digest_md5  => 'b09e26c292759d654633d3c8ed00d18d',

                # Optionally:
                response    => $response_text
            },
            ...
        ],

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

use MIME::Parser 5.4;
use Digest::MD5;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant DEFAULT_RESPONSE   => 'Prohibited MIME part detected.';

# Interface:
##############################################################################

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if one of the message's MIME parts matches one of the configured
signatures.

=cut

sub new;

sub match;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item new(%options): RETURNS Courier::Filter::Module::MIMEParts

Creates a new B<MIMEParts> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item max_size

An integer value controlling the maximum size (in bytes) of the overall message
text for a message to be processed by this filter module.  Messages larger than
this value will never be processed, and thus will never match.  If B<undef>,
there is no size limit.  Defaults to B<undef>.

As MIME processing is completely done in-memory in this version of the filter
module, you should definitely restrict the message size to some sensible value
that easily fits in your server's memory.  1024**2 (1MB) should be appropriate
for most uses of this filter module.

=item signatures

REQUIRED.  A reference to an array containing the list of I<signatures> against
which messages' MIME parts are to be matched.  A signature in turn is a
reference to a hash containing one or more so-called signature I<aspects> (as
key/value pairs).  Aspects may either be scalar values (for exact,
case-sensitive matches), or regular expression objects created with the C<qr//>
operator (for inexact, partial matches).

For a signature to match a MIME part, I<all> of the signature's aspects must
match those of the MIME part.  For the filter module to match a message, I<any>
of the signatures must match I<any> of the message's MIME parts.

An aspect can be any of the following:

=over

=item mime_type

The MIME type of the MIME part ('type/sub-type').

=item file_name

The file name of the MIME part.

=item size

The exact size (in bytes) of the decoded MIME part.

=item digest_md5

The MD5 digest of the decoded MIME part (32 hex digits, as printed by
`md5sum`).

=back

Every signature may also contain a C<response> option containing a string that
is to be returned as the match result in case of a match.  Defaults to
B<"Prohibited MIME part detected.">.

So for instance, a signature list could look like this:

    signatures  => [
        {
            mime_type   => qr/html/,
            response    => 'No HTML mail, please.'
        },
        {
            file_name   => qr/\.(exe|com|pif|lnk)$/,
            response    => 'Executable content detected'
        },
        {
            size        => 106496,
            digest_md5  => 'b09e26c292759d654633d3c8ed00d18d',
            response    => 'Worm detected: W32.Swen'
        },
        {
            size        => 22528,
            response    => 'Worm suspected: W32.Mydoom'
        }
    ]

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new()"> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    my $mime_parser = MIME::Parser->new();
    $mime_parser->output_to_core(TRUE);
    $mime_parser->tmp_to_core(TRUE);
    
    my $module = $class->SUPER::new(
        %options,
        mime_parser => $mime_parser
    );
    
    foreach my $signature ( @{$module->{signatures}} ) {
        $module->compile_signature($signature);
    }
    
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
    
    return undef
	if  defined($module->{max_size}) and
	    -s $message->file_name > $module->{max_size};
    
    my $text = $message->text;
    
    my $entity = $module->{mime_parser}->parse_data($text);
    my ($result, @code) = $module->match_mime_entity($entity);
    
    $result &&= 'MIMEParts: ' . $result;
    
    return ($result, @code);
}

sub match_mime_entity {
    my ($module, $entity) = @_;
    
    if (my $body = $entity->bodyhandle) {
	# No sub-parts, match this part:
	
	# Distill reference signature from this MIME part:
        my $signature = $module->distill_signature($entity);
	
        # Try matching all configured signatures:
	foreach my $testsig ( @{$module->{signatures}} ) {
            my ($result, @code) = $testsig->{matcher}->($signature);
            return ($result, @code) if defined($result);
	}
    }
    else {
	# Match all sub-parts:
	foreach my $subentity ($entity->parts) {
	    my ($result, @code) = $module->match_mime_entity($subentity);
	    return ($result, @code) if defined($result);
	}
    }
    
    return undef;
}

sub distill_signature {
    my ($module, $entity) = @_;
    
    my $head = $entity->head;
    my $body = $entity->bodyhandle;
    my $text = $body->as_string;
    
    return {
        mime_type   => $head->mime_type,
        file_name   => $head->recommended_filename,
        size        => length($text),
        digest_md5  => Digest::MD5::md5_hex($text)
    };
}

sub compile_signature {
    my ($module, $signature) = @_;

    my %matchers;

    my @aspects = grep($_ ne 'response', keys(%$signature));
    foreach my $aspect (@aspects) {
        my $pattern = $signature->{$aspect};
        
        my $matcher;
        if (ref($pattern) eq 'Regexp') {
            $matcher = sub { $_[0] =~ $pattern };
        }
        elsif (ref($pattern) eq 'CODE') {
            $matcher = $pattern;
        }
        else {
            $matcher = sub { $_[0] eq $pattern };
        }
        
        $matchers{$aspect} = $matcher;
    }
    
    my @response =
        ref($signature->{response}) eq 'ARRAY' ?
            @{ $signature->{response} }
        :   ($signature->{response} || DEFAULT_RESPONSE);
    
    my $matcher = sub {
        my ($signature) = @_;
        
        foreach my $aspect (keys(%matchers)) {
            my $value = $signature->{$aspect};
            return undef
                if not defined($value)
                or not $matchers{$aspect}->($value);
        }
        return @response;
    };
    
    $signature->{matcher} = $matcher;
    
    return;
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
