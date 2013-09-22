
use warnings;
use integer;
use strict 'vars';
package Text::Bidi::Constants;
# ABSTRACT: Constants for Text::Bidi

=head1 DESCRIPTION

This module provides various constants defined by the fribidi library. They 
can be used with some of the low-level functions in L<Text::Bidi>, such as 
L<Text::Bidi/get_bidi_types>, but are of little interest as far as standard 
usage is concerned.

Note that, though these are variables, they are read-only.

=over

=cut

SYM: for my $sym ( keys %Text::Bidi::private:: ) {
    next unless $sym =~ /^FRIBIDI_/;

=item *

Constants of the form B<FRIBIDI_TYPE_FOO> are available as 
C<$Text::Bidi::Type::FOO>. See fribidi_get_bidi_type(3) for possible constants.

=item *

Constants of the form B<FRIBIDI_MASK_FOO> are converted to 
C<$Text::Bidi::Mask::FOO>. See F<fribidi-bidi-types.h> for possible masks and 
how to use them.

=item *

Constants of the form B<FRIBIDI_PAR_FOO> are converted to 
C<$Text::Bidi::Par::FOO>. See fribidi_get_par_embedding_levels(3) for 
possible constants.

=item *

Constants of the form B<FRIBIDI_FLAG_FOO> are converted to 
C<$Text::Bidi::Flag::FOO>. See fribidi_reorder_line(3) and fribidi_shape(3) 
for possible constants.

=cut

    for my $kind ( qw(Type Mask Par Flag) ) {
        if ( $sym =~ /FRIBIDI_\U${kind}\E_([A-Z_]*)$/ ) {
            *{"Text::Bidi::$kind::$1"} = *{"Text::Bidi::private::$sym"};
            next SYM;
        }
    }

=item *

Constants of the form B<FRIBIDI_JOINING_TYPE_FOO> are converted to 
C<$Text::Bidi::Joining::FOO>. See fribidi_get_joining_type(3) for 
possible constants.

=cut

    if ( $sym =~ /FRIBIDI_JOINING_TYPE_([A-Z])_VAL/ ) {
        *{"Text::Bidi::Joining::$1"} = *{"Text::Bidi::private::$sym"};
        next SYM;
    }

=item *

Constants of the form B<FRIBIDI_CHAR_FOO> are converted to the character they 
represent, and assigned to C<$Text::Bidi::Char::FOO>. See 
F<fribidi-unicode.h> for possible constants.

=cut

    if ( $sym =~ /FRIBIDI_CHAR_([A-Z_]*)$/ ) {
        no warnings 'once';
        ${"Text::Bidi::Char::$1"} = \chr(${"Text::Bidi::private::$sym"});
        next SYM;
    }
}

=back

=head1 SEE ALSO

L<Text::Bidi>

=cut

1;

