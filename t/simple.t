#! perl -T

use utf8;
use Test::More tests => 3;
use open ':encoding(utf-8)';
use open ':std';

BEGIN {
our %Tests = (
    'abcאבג' => 'abcגבא',
    'אבגabc' => 'abcגבא',
    'abc אבג def דהו' => 'abc גבא def והד',
);
}

use Text::Bidi qw(log2vis);

is(log2vis($_), $Tests{$_}, $_) foreach keys %Tests;

1;
