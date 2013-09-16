# $Id$
# Created: Tue 27 Aug 2013 04:10:03 PM IDT
# Last Changed: Wed 11 Sep 2013 11:49:51 AM IDT

package Text::Bidi::Paragraph;

=head1 NAME

Text::Bidi::Paragraph - Run the bidi algorithm on one paragraph

=head1 SYNOPSIS

    use Text::Bidi::Paragraph;

    my $par = new Text::Bidi::Paragraph $logical;
    my $offset = 0;
    my $width = 80;
    while ( $offset < $p->len ) {
        my $v = $p->visual($offset, $width);
        say $v;
        $offset += $width;
    }

=head1 DESCRIPTION

This class provides the main interface for applying the bidi algorithm in 
full generality. In the case where the paragraph spans only one visual line, 
L<Text::Bidi/log2vis> can be used as a shortcut.

A paragraph is processed by creating a L<Text::Bidi::Paragraph> object:

    $par = new Text::Bidi::Paragraph $logical;

Here C<$logical> is the text of the paragraph. This applies the first stages 
of the bidi algorithm: computation of the embedding levels. Once this is 
done, the text can be displayed using the L</visual()> method, which does the 
reordering.

=cut

use 5.10.0;
use warnings;
#no warnings 'experimental';
use integer;
use strict;

use Text::Bidi;

our $VERSION = 2.01;


=head1 METHODS

=head2 new()

    my $par = new Text::Bidi::Paragraph $logical, ...;

Create a new object corresponding to a text B<$logical> in logical order. The 
other arguments are key-value pairs. The only ones that have a meaning at the 
moment are I<bd>, which supplies the L<Text::Bidi> object to use, and 
I<dir>, which prescribes the direction of the paragraph. The value of I<dir> 
is a constant in C<Text::Bidi::Par::> (e.g., C<$Text::Bidi::Par::RTL>).

Note that the mere creation of B<$par> runs the bidi algorithm on the given 
text B<$logical> up to the point of reordering (which is dealt with in 
L</visual()>).

=cut

sub new {
    my $class = shift;
    my $par = shift;
    my $self = { @_ };
    my @bd = ($self->{'bd'});
    $self->{'bd'} = Text::Bidi::S(@bd);
    $self->{'par'} = $par;
    bless $self => $class;
    $self->init;
    $self
}

=head2 par()

    my $logical = $par->par;

Returns the logical (input) text corresponding to this paragraph.

=head2 dir()

    my $dir = $par->dir;

Returns the direction of this paragraph, a constant in the 
C<$Text::Bidi::Par::> package.

=head2 len()

    my $len = $par->len;

The length of this paragraph.

=head2 types()

    my $types = $par->types;

The Bidi types of the characters in this paragraph. Each element of 
C<@$types> is a constant in the C<$Text::Bidi::Type::> package.

=head2 levels()

    my $levels = $par->levels;

The embedding levels for this paragraph. Each element of C<@$levels> is an 
integer.

=cut

for my $f ( qw(par bd dir _par _mirpar)) {
    no strict 'refs';
    *$f = sub { $_[0]->{$f} };
}

for my $f ( qw(len unicode types levels mirrored map) ) {
    no strict 'refs';
    *$f = sub { $_[0]->{"_$f"} };
}

=head2 is_rtl()

    my $rtl = $par->is_rtl;

Returns true if the direction of the paragraph is C<RTL> (right to left).

=cut

sub is_rtl { $_[0]->dir == $Text::Bidi::Par::RTL }

sub init {
    my ($self) = (@_);
    my $par = $self->par;
    $self->{'_len'} = length($par);
    my $bd = $self->bd;
    $self->{'_unicode'} = $bd->utf8_to_internal($par);
    #$self->{'_par'} = [split '', $par];
    $self->{'_types'} = $bd->get_bidi_types($self->unicode);
    (my $d, $self->{'_levels'}) =
        $bd->get_par_embedding_levels($self->types, $self->dir);
    $self->{'dir'} //= $d;
    $self->{'_map'} = [0..$#{$self->unicode}];
    $self->{'_mirrored'} = $bd->mirrored($self->levels, $self->unicode);
    $self->{'_mirpar'} = $bd->internal_to_utf8($self->mirrored);
    $self->{'_par'} = [split '', $self->_mirpar ];
}

=head2 visual()

    my $visual = $par->visual($offset, $length, $flags);

Return the visual representation of the part of the paragraph B<$par> 
starting at B<$offset> and of length B<$length>. B<$par> is a 
L<Text::Bidi::Paragraph> object. All arguments are optional, with B<$offset> 
defaulting to C<0> and B<$length> to the length till the end of the paragraph 
(see below from B<$flags>).

Note that this method does not take care of right-justifying the text if the 
paragraph direction is C<RTL>. Hence a typical application might look as 
follows:

    my $visual = $par->visual($offset, $width, $flags);
    my $len = length($visual);
    $visual = (' ' x ($width - $len)) . $visual if $par->is_rtl;

Note also that the length of the result might be strictly less than 
B<$length>.

The B<$flags> argument, if defined, should be either a hashref or an integer.  
If it is a number, its meaning is the same as in C<fribidi_reorder_line(3)>.  
A hashref is converted to the corresponding values for keys whose value is 
true. The keys should be the same as the constants in F<fribidi-types.h>, 
with the prefix C<FRIBIDI_FLAGS_> removed.

In addition, the B<$flags> hashref may contain lower-case keys. The only one 
recognised at the moment is I<break>. Its value, if given, should be a string 
at which the line should be broken. Hence, if this key is given, the actual 
length is potentially reduced, so that the line breaks at the given string 
(if possible). A typical value for I<break> is C<' '>.

=cut

sub visual {
    my ($self, $off, $len, $flags) = @_;
    $off //= 0;
    $len //= $self->len;
    my $mlen = $self->len - $off;
    $mlen = $len if $len < $mlen;
    if (my $break = eval { $flags->{'break'} } ) {
        my $lb = length($break);
        my $nlen = rindex($self->par, $break, $off + $mlen - $lb) - $off + $lb;
        $mlen = $nlen if $nlen > 0;
    }
    my $bd = $self->bd;
    (my $levels, $self->{'_map'}) = 
      $bd->reorder_map($self->types, $off, $mlen, $self->dir, 
                       $self->map, $self->levels, $flags);
    $self->{'_levels'} = $bd->tie_byte($levels);
    $bd->reorder($self->_par, $self->map, $off, $mlen)
}

1;

__END__

=head1 SEE ALSO

L<Text::Bidi>

=head1 AUTHOR

Moshe Kamensky  (E<lt>kamensky@cpan.orgE<gt>) - Copyright (c) 2013

=head1 LICENSE

This program is free software. You may copy or 
redistribute it under the same terms as Perl itself.

=cut

