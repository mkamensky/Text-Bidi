# $Id$
# Created: Tue 27 Aug 2013 06:12:39 PM IDT
# Last Changed: Wed 11 Sep 2013 11:47:05 AM IDT

=head1 NAME

Text::Bidi::Array::Long - Dual-life long arrays

=head1 SYNOPSIS

    use Text::Bidi::Array::Long;
    my $a = new Text::Bidi::Array::Long "abc";
    say $a->[0]; # says 6513249 (possibly)
    say $a->[1]; # says 0
    say $$a; # says abc
    say "$a"; # also says abc



=head1 DESCRIPTION

This is an derived class of L<Text::Bidi::Array> designed to hold C<long> 
arrays. See L<Text::Bidi::Array> for details on usage of this class. Each 
element of the array representation corresponds to 4 octets in the string 
representation. The 4 octets are packed in the endianness of the native 
machine.

=cut

package Text::Bidi::Array::Long;

use 5.10.0;
use warnings;
use integer;
use strict;
use Carp;


our $VERSION = 1.1;

use Text::Bidi::Array;
use base qw(Text::Bidi::Array);

BEGIN {
# fribidi uses native endianness, vec uses N (big-endian)

    use Config;

    if ( $Config{'byteorder'} % 10 == 1 ) {
        # big-endian
        *big_to_native = sub { @_ };
        *native_to_big = sub { @_ };
    } else {
        *big_to_native = sub { unpack('L*', pack('N*', @_)) };
        *native_to_big = sub { unpack('N*', pack('L*', @_)) };
    }
}

sub pack {
    shift;
    pack('L*', @_)
}

sub STORE {
    my ( $self, $i, $v ) = @_;
    vec($self->{'data'}, $i, 32) = native_to_big($v)
}

sub FETCH {
    my ( $self, $i ) = @_;
    big_to_native(vec($self->{'data'}, $i, 32))
}

sub FETCHSIZE {
    (length($_[0]->{'data'})+3)/4
}

sub STORESIZE {
    my ($self, $s) = @_;
    if ($self->FETCHSIZE >= $s ) {
        substr($self->{'data'}, $s * 4) = '';
    } else {
        $self->STORE($s - 1, 0);
    }
}

1;

__END__

=head1 AUTHOR

Moshe Kamensky  (E<lt>kamensky@cpan.orgE<gt>) - Copyright (c) 2013

=head1 LICENSE

This program is free software. You may copy or 
redistribute it under the same terms as Perl itself.

=cut

