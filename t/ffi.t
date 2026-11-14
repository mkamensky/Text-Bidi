use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use FFI::CheckLib qw(find_lib_or_die);
use IPC::Open3;
use Symbol qw(gensym);
use Text::Bidi qw(log2vis fribidi_version_num unicode_version);
use Text::Bidi::Constants;

like fribidi_version_num(), qr/^\d+\.\d+\.\d+$/, 'runtime library version';
like unicode_version(), qr/^\d+\.\d+\.\d+$/, 'runtime Unicode version';

for my $name (qw(FRIBIDI_TYPE_LTR FRIBIDI_PAR_RTL FRIBIDI_FLAGS_DEFAULT
                 FRIBIDI_BRACKET_OPEN_MASK FRIBIDI_JOINING_TYPE_D_VAL
                 version_info unicode_version)) {
    no strict 'refs';
    my $before = ${"Text::Bidi::private::$name"};
    my $ok = eval { ${"Text::Bidi::private::$name"} = 0; 1 };
    ok !$ok, "$name is read-only";
    is ${"Text::Bidi::private::$name"}, $before, "$name remains unchanged";
}
ok !eval { $Text::Bidi::Par::RTL = 0; 1 }, 'public constant aliases remain read-only';

my $bidi = Text::Bidi->new;
my $chars = $bidi->utf8_to_internal("\x{5d0}\x{5d1}");
my $types = $bidi->get_bidi_types($chars);
my ($max, $dir, $levels) = Text::Bidi::private::get_par_embedding_levels(
    $$types, $Text::Bidi::Par::ON);
is $max, 2, 'legacy embedding function returns maximum level plus one';
is $dir, $Text::Bidi::Par::RTL, 'legacy embedding function resolves direction';
is_deeply $levels, [1, 1], 'legacy embedding levels';
is_deeply scalar Text::Bidi::private::get_par_embedding_levels(
    $$types, $Text::Bidi::Par::ON), [1, 1], 'scalar context returns final output';
is_deeply [Text::Bidi::private::log2vis_get_embedding_levels(
    $$types, $Text::Bidi::Par::ON)], [$max, $dir, $levels],
    'deprecated embedding entry point retains its calling convention';
for my $lookup (\&Text::Bidi::private::get_type,
                \&Text::Bidi::private::get_type_internal) {
    is $lookup->(0x5d0), $types->[0], 'deprecated character type lookup';
}

my $types_snapshot = [@$types];
$bidi->get_bidi_types($bidi->utf8_to_internal('abc'));
is_deeply [@$types], $types_snapshot, 'native output survives subsequent calls';

my $ltr_types = $bidi->get_bidi_types($bidi->utf8_to_internal('a'));
my (undef, $sentinel_map) = $bidi->reorder_map(
    $ltr_types, 0, 1, $Text::Bidi::Par::LTR, [-1]);
is_deeply $sentinel_map, [~0], 'map sentinel retains unsigned Perl representation';

my (undef, $packed) = Text::Bidi::private::utf8_to_internal("a\0b");
my ($bytes, $text) = Text::Bidi::private::internal_to_utf8($packed);
is $bytes, 3, 'conversion returns byte count including embedded NUL';
is $text, "a\0b", 'conversion does not stop at NUL';
is Text::Bidi::private::get_par_direction(''), $Text::Bidi::Par::ON,
    'empty direction lookup';
is_deeply Text::Bidi::private::get_joining_types(''), [], 'empty joining lookup';
is_deeply Text::Bidi::private::get_bracket_types('', ''), [], 'empty bracket lookup';
is Text::Bidi::private::shape_mirroring('', ''), '', 'empty mirroring';
is_deeply Text::Bidi::private::join_arabic('', '', ''), [], 'empty Arabic joining';
is_deeply [Text::Bidi::private::shape_arabic(0, '', '', '')], [[], ''],
    'empty Arabic shaping';

# Exercise library selection in a fresh interpreter: the parent already has
# its library loaded. Keep stderr separate so loader failures are observable.
sub load_with_library {
    my ($library) = @_;
    local $ENV{TEXT_BIDI_FRIBIDI_LIB} = $library;
    local $ENV{PERL5LIB} = join $Config::Config{path_sep} || ':',
        grep { !ref } @INC;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, '-MText::Bidi', '-e',
        'print scalar Text::Bidi::log2vis("abc")');
    close $in;
    local $/;
    my $stdout = <$out>;
    my $stderr = <$err>;
    waitpid $pid, 0;
    return ($?, $stdout, $stderr);
}

my $library = find_lib_or_die(lib => 'fribidi');
my ($status, $stdout, $stderr) = load_with_library($library);
is $status, 0, 'explicit shared-library path loads successfully' or diag $stderr;
is $stdout, 'abc', 'public API works with explicit library path';
($status, $stdout, $stderr) = load_with_library($library . '.does-not-exist');
ok $status != 0, 'missing explicitly selected library fails to load';
like $stderr, qr/FriBidi|fribidi/, 'missing-library diagnostic identifies FriBidi';

done_testing;
