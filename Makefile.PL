use strict;
use warnings;

##{ $perl_prereq ? qq[use $perl_prereq;] : ''; ##}

use ExtUtils::MakeMaker;
use FFI::CheckLib 0.28 qw(check_lib_or_exit);

# A missing system dependency makes the distribution inapplicable to CPAN
# Testers. Exit successfully before generating a Makefile in that case.
check_lib_or_exit(lib => 'fribidi') unless $ENV{TEXT_BIDI_FRIBIDI_LIB};

my %WriteMakefileArgs;
##{ use Data::Dumper; Data::Dumper->Dump([\%default_args], [ '*WriteMakefileArgs' ]) ##}

# Dist::Zilla supplies release metadata; a checkout also builds directly.
%WriteMakefileArgs = (
    NAME => 'Text::Bidi',
    VERSION => '0.00',
    MIN_PERL_VERSION => '5.010000',
    CONFIGURE_REQUIRES => { 'FFI::CheckLib' => '0.28' },
    PREREQ_PM => {
        'FFI::CheckLib' => '0.28',
        'FFI::Platypus' => '2.00',
        'version' => '0.77',
    },
    TEST_REQUIRES => { 'Test::More' => 0 },
    %WriteMakefileArgs,
    # Ignore generated C files left over from a former SWIG checkout.
    XS => {},
    C => [],
    OBJECT => '',
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
    my $br = $WriteMakefileArgs{BUILD_REQUIRES} ||= {};
    for my $mod (keys %$tr) {
        $br->{$mod} = $tr->{$mod}
            unless exists $br->{$mod} && $br->{$mod} >= $tr->{$mod};
    }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    my $pp = $WriteMakefileArgs{PREREQ_PM} ||= {};
    for my $mod (keys %$br) {
        $pp->{$mod} = $br->{$mod}
            unless exists $pp->{$mod} && $pp->{$mod} >= $br->{$mod};
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
