#
# Courier::Filter::Module::Header class
#
# (C) 2004 Julian Mehnle <julian@mehnle.net>
#
# $Id: Header.pm,v 1.3 2004/02/17 13:37:50 julian Exp $
#
##############################################################################

=head1 NAME

Courier::Filter::Module::Header - A message header filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::Header;

=head1 VERSION

0.1

=cut

our $VERSION = 0.1;

=head1 SYNOPSIS

    use Courier::Filter::Module::Header;

    my $module = Courier::Filter::Module::Header->new(
        fields      => \%patterns_by_field_name,
        response    => $response_text,

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

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if one of the message's header fields matches the configured criteria.

=cut

sub match;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS Courier::Filter::Module::Header

Creates a new B<Header> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<fields>

REQUIRED.  A reference to a hash containing the message header field names and
patterns (as key/value pairs) that messages are to be matched against.  Field
names are matched case-insensitively.  Patterns may either be simple strings
(for exact, case-sensitive matches) or regular expression objects created by
the C<qr//> operator (for inexact, partial matches).

So for instance, to match any message from the "debian-devel" mailing list with
the subject containing something about 'duelling banjoes', you could set the
C<fields> option as follows:

    fields      => {
       'list-id'    => '<debian-devel.lists.debian.org>',
        subject     => qr/duell?ing\s+banjoe?s?/i
    }

=item B<response>

A string that is to be returned literally as the match result in case of a
match.  Defaults to B<< "Prohibited header value detected: <field>: <value>" >>.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new()"> for their descriptions.

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($module, $message) = @_;
    my $class = ref($module);
    
    my $fields = $module->{fields};
    foreach my $field (keys(%$fields)) {
        my $pattern = $fields->{$field};
        my $matcher =
            UNIVERSAL::isa($pattern, 'Regexp') ?
                sub { $_[0] =~ $pattern }
            :   sub { $_[0] eq $pattern };
        
        my @values = $message->header($field);
        
        foreach my $value (@values) {
            if ($matcher->($value)) {
                return
                    $module->{response} ||
                    'Prohibited header value detected: ' .
                        ucfirst(lc($field)) . ': ' . $value;
            }
        }
    }
    
    return undef;
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
