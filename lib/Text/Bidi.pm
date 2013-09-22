use 5.10.0;
use warnings;
#no warnings 'experimental';
use strict 'vars';

package Text::Bidi;
# ABSTRACT: Unicode bidi algorithm using libfribidi

use Exporter;
use base qw(Exporter);
use Carp;

use Text::Bidi::private;
use Text::Bidi::Array::Byte;
use Text::Bidi::Array::Long;
use Encode qw(encode decode);

=head1 SYNOPSIS

    # Each displayed line is a "paragraph"
    use Text::Bidi qw(log2vis);
    ($par, $map, $visual) = log2vis($logical);
    # or just
    $visual = log2vis(...);

    # with real paragraphs:
    $p = new Text::Bidi::Paragraph $logical;
    $visual = $p->visual($off, $len);

=head1 EXPORT

The following functions can be exported (nothing is exported by default):

=over

=item *

L</log2vis()>

=item *

L</is_bidi()>

=item *

L</get_mirror_char()>

=back

All of them can be exported together using the C<:all> tag.

=cut

BEGIN {
    our %EXPORT_TAGS = (
        'all' => [ qw(
            log2vis
            is_bidi
            get_mirror_char
        ) ],
    );
    our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'}} );
}

=head1 DESCRIPTION

This module provides basic support for the Unicode bidirectional (Bidi) text 
algorithm, for displaying text consisting of both left-to-right and 
right-to-left written languages (such as Hebrew and Arabic.) It does so via  
a I<swig> interface file to the I<libfribidi> library.

The fundamental purpose of the bidi algorithm is to reorder text given in 
logical order into text in visually correct order, suitable for display using 
standard printing commands. ``Logical order'' means that the characters are 
given in the order in which they would be read if printed correctly. The 
direction of the text is determined by properties of the unicode characters, 
usually without additional hints.  See 
L<http://www.unicode.org/unicode/reports/tr9/> for more details on the 
problem and the algorithm.

=head2 Standard usage

The bidi algorithm works in two stages. The first is on the level of a 
paragraph, where the direction of each character is computed. The second is 
on the level of the lines to be displayed. The main practical difference is 
that the first stage requires only the text of the paragraph, while the 
second requires knowledge of the width of the displayed lines. The module (or 
the library) does not determine how the text is broken into paragraphs.

The main interface is provided by L<Text::Bidi::Paragraph>, see there for 
details. This module provides an abreviation, L</log2vis()>, which combines 
creating a paragraph object with calling L<Text::Bidi::Paragraph/visual> 
on it.  It is particularly useful in the case that every line is a paragraph 
on its own:

    $visual = log2vis($logical);

There are more options (see the corresponding section), but this is 
essentially it. The rest of this documentation will probably be useful only 
to people who are familiar with I<libfribidi> and who wish to extend or 
modify the module.

=head2 The object oriented approach

All functions here can be called using either a procedural or an object 
oriented approach. For example, you may do either

        $visual = log2vis($logical);

or

        $bidi = new Text::Bidi;
        $visual = $bidi->log2vis($logical);

The advantages of the second form is that it is easier to move to a 
sub-class, and that two or more objects with different parameters can be used 
simultaneously.

If you do sub-class this class, and want the procedural interface to use your 
functions, put a line like

        $Text::Bidi::GlobalClass = __PACKAGE__;

in your module.

=cut

# The following mechanism is used to provide both kinds of interface: Every 
# method starts with 'my $self = S(@_)' instead of 'my $self = shift'. S 
# shifts and returns the object if there is one, or returns a global object, 
# stored in $Global, if there is in @_. The first time $Global is needed, it 
# is created with type $GlobalClass.

my $Global;
our $GlobalClass = __PACKAGE__;

=for Pod::Coverage S

=cut

sub S(\@) {
    my $l = shift;
    my $s = $l->[0];
    return shift @$l if eval { $s->isa('Text::Bidi') };
    $Global = new $GlobalClass unless $Global;
    $Global
}

=method new

    $tb = new Text::Bidi [tie_byte => ..., tie_long => ...];

Create a new L<Text::Bidi> object. If the I<tie_byte> or I<tie_long> options 
are given, they should be the names (strings) of the classes used as dual 
life arrays, most probably derived class of L<Text::Bidi::Array::Byte> and 
L<Text::Bidi::Array::Long>, respectively.

This method is probably of little interest for standard (procedural) use.

=cut

sub new {
    my $class = shift;
    my $self = {
        tie_byte => 'Text::Bidi::Array::Byte',
        tie_long => 'Text::Bidi::Array::Long',
        @_
    };
    bless $self => $class
}

=for Pod::Coverage tie_byte tie_long

=cut

sub tie_byte {
    my $self = shift;
    $self->{'tie_byte'}->new(@_)
}

sub tie_long {
    my $self = shift;
    $self->{'tie_long'}->new(@_)
}

=method utf8_to_internal

    $la = $tb->utf8_to_internal($str);

Convert the Perl string I<$str> into the representation used by libfribidi.  
The result will be a L<Text::Bidi::Array::Long>.

=cut

sub utf8_to_internal {
    my $self = S(@_);
    my $str = shift;
    my ($i, $res) = 
      Text::Bidi::private::utf8_to_internal(encode('utf8', $str));
    $self->tie_long($res)
}

=method internal_to_utf8

    $str = $tb->internal_to_utf8($la);

Convert the long array I<$la>, representing a string encoded in to format 
used by libfribidi, into a Perl string. The array I<$la> can be either a 
L<Text::Bidi::Array::Long>, or anything that can be used to construct it.

=cut

sub internal_to_utf8 {
    my $self = S(@_);
    my $u = shift;
    $u = $self->tie_long($u) unless eval { defined $$u };
    my $r = Text::Bidi::private::internal_to_utf8($$u);
    decode('utf8', $r)
}

=method get_bidi_types

    $types = $tb->get_bidi_types($internal);

Returns a L<Text::Bidi::Array::Long> with the list of Bidi types of the text 
given by $internal, a representation of the paragraph text, as returned by 
utf8_to_internal(). Wraps fribidi_get_bidi_types(3).

=cut

sub get_bidi_types {
    my $self = S(@_);
    my $u = shift;
    my $t = Text::Bidi::private::get_bidi_types($$u);
    $self->tie_long($t)
}

=method get_bidi_type_name

    say $tb->get_bidi_type_name($Text::Bidi::Type::LTR); # says 'LTR'

Return the string representation of a Bidi character type, as in 
fribidi_get_bidi_type_name(3). Note that for the above example, one needs to 
use L<Text::Bidi::Constants>.

=cut

sub get_bidi_type_name {
    my $self = S(@_);
    Text::Bidi::private::get_bidi_type_name(@_)
}

=method get_joining_types

    $types = $tb->get_joining_types($internal);

Returns a L<Text::Bidi::Array::Byte> with the list of joining types of the 
text given by $internal, a representation of the paragraph text, as returned 
by L</utf8_to_internal>. Wraps fribidi_get_joining_types(3).

=cut

sub get_joining_types {
    my $self = S(@_);
    my $u = shift;
    $self->tie_byte(Text::Bidi::private::get_joining_types($$u))
}

sub get_joining_type_name {
    my $self = S(@_);
    Text::Bidi::private::get_joining_type_name(@_)
}

sub get_par_embedding_levels {
    my $self = S(@_);
    my $bt = shift;
    my $p = shift // $Text::Bidi::private::FRIBIDI_PAR_ON;
    my ($lev, $par, $out) = 
        Text::Bidi::private::get_par_embedding_levels($$bt, $p);
    my $res = $self->tie_byte($out);
    ($par, $res)
}

sub mirrored {
    my $self = S(@_);
    my ($el, $u) = @_;
    my $r =Text::Bidi::private::shape_mirroring($$el, $$u);
    my $res = $self->tie_long($r)
}

sub hash2flags {
    my ($self, $flags) = @_;
    my $res = 0;
    foreach ( keys %$flags ) {
        next unless $flags->{$_};
        next unless $_ eq uc;
        my $v = 'Text::Bidi::private::FRIBIDI_FLAG_' . uc($_);
        $res |= $$v;
    }
    $res
}

sub reorder {
    my $self = S(@_);
    my ($str, $map, $off, $len) = @_;
    $off //= 0;
    $len //= @$str;
    join('', (@$str)[@$map[$off..$off+$len-1]])
}

sub reorder_map {
    my $self = S(@_);
    my ($bt, $off, $len, $par, $map, $el, $flags) = @_;
    unless ( defined $el ) {
        (my $p, $el) = $self->get_par_embedding_levels($bt, $par);
        $par //= $p;
    }
    if ( defined $flags ) {
        $flags = $self->hash2flags($flags) if ref $flags;
    } else {
        $flags = $Text::Bidi::private::FRIBIDI_FLAGS_DEFAULT;
    }
    $map //= [0..$#$bt];

    $map = $self->tie_long($map) unless eval {defined $$map};

    my ($lev, $elout, $mout) = Text::Bidi::private::reorder_map(
        $flags, $$bt, $off, $len, $par, $$el, $$map);
    ($elout, $mout)
}

=func log2vis()

    my $visual = log2vis($logical,...);

Treat the input B<$logical> as a one line paragraph, and apply all stages of 
the algorithm to it. This works well if the paragraph does indeed span only 
one visual line. The other arguments are passed to 
L<Text::Bidi::Paragraph/visual>, but this is probably worthless.

=cut

sub log2vis {
    require Text::Bidi::Paragraph;
    my $log = shift;
    my $p = new Text::Bidi::Paragraph $log;
    my $res = $p->visual(@_);
    ($p, $res)
}

=func is_bidi()

    my $bidi = is_bidi($logical);

Returns true if the input B<$logical> contains bidi characters. Otherwise, 
the output of the bidi algorithm will be identical to the input, hence this 
helps if we want to short-circuit.

=cut

sub is_bidi { $_[0] =~ /\p{bc=R}/ }

=func get_mirror_char()

    my $mir = get_mirror_char('['); # $mir == ']'

Return the mirror character of the input, possibly itself.

=cut

sub get_mirror_char {
    my $self = S(@_);
    my $u = shift;
    $u = $self->utf8_to_internal($u) unless ref($u);
    my $r = Text::Bidi::private::get_mirror_char($u->[0]);
    my $res = $self->tie_long([$r]);
    wantarray ? ($res) : $self->internal_to_utf8($res)
}

=head1 BUGS

There are no real tests for any of this.

Shaping is not supported (probably), since I don't know what it is. Help 
welcome!

=head1 SEE ALSO

L<Text::Bidi::Paragraph>

L<Encode>

L<The fribidi library|http://fribidi.org/>

L<Swig|http://www.swig.org>

L<The unicode bidi algorithm|http://www.unicode.org/unicode/reports/tr9/>

=cut

1; # End of Text::Bidi

