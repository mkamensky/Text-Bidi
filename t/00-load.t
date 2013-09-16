#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Text::Bidi' );
	use_ok( 'Text::Bidi::Paragraph' );
        use_ok( 'Text::Bidi::Array' );
        use_ok( 'Text::Bidi::Array::Byte' );
        use_ok( 'Text::Bidi::Array::Long' );
}

diag( "Testing Text::Bidi $Text::Bidi::VERSION, Perl $], $^X" );
