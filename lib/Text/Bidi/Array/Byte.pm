# $Id$
# Created: Tue 27 Aug 2013 06:09:42 PM IDT
# Last Changed: Wed 11 Sep 2013 11:44:57 AM IDT

=head1 NAME

Text::Bidi::Array::Byte - Dual-life byte arrays

=head1 SYNOPSIS

    use Text::Bidi::Array::Byte;
    my $a = new Text::Bidi::Array::Byte "abc";
    say $a->[1]; # says 98
    say $$a; # says abc
    say "$a"; # also says abc

=head1 DESCRIPTION

This is an derived class of L<Text::Bidi::Array> designed to hold C<byte> 
arrays. See L<Text::Bidi::Array> for details on usage of this class. Each 
element of the array representation corresponds to an octet in the string 
representation, at the same location.

=cut

package Text::Bidi::Array::Byte;

use 5.10.0;
use warnings;
use integer;
use strict;
use Carp;

our $VERSION = 1.1;

use Text::Bidi::Array;
use base qw(Text::Bidi::Array);

sub pack {
    shift;
    pack('C*', @_)
}

sub STORE {
    my ( $self, $i, $v ) = @_;
    vec($self->{'data'}, $i, 8) = $v
}

sub FETCH {
    my ( $self, $i ) = @_;
    vec($self->{'data'}, $i, 8)
}

sub FETCHSIZE {
    length($_[0]->{'data'})
}

sub STORESIZE {
    my ($self, $s) = @_;
    if ($self->FETCHSIZE >= $s ) {
        substr($self->{'data'}, $s) = '';
    } else {
        $self->STORE($s - 1, 0);
    }
}

1;

=head1 AUTHOR

Moshe Kamensky  (E<lt>kamensky@cpan.orgE<gt>) - Copyright (c) 2013

=head1 LICENSE

This program is free software. You may copy or 
redistribute it under the same terms as Perl itself.

=cut

