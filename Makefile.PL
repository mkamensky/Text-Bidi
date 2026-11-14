use strict;
use warnings;
use version 0.77;

##{ $perl_prereq ? qq[use $perl_prereq;] : ''; ##}

use ExtUtils::MakeMaker;
use File::Find;

my (%fribidi, $libs, $cflags);

my $min_fribidi = '1.0.0';

if ( eval { require ExtUtils::PkgConfig; 1 } ) {
    %fribidi = eval { ExtUtils::PkgConfig->find('fribidi') };
}
unless (%fribidi) {
    # Use pkg-config directly when the optional Perl helper is unavailable.
    my $pkg_config = $ENV{PKG_CONFIG} || 'pkg-config';
    for my $field (qw(modversion cflags libs)) {
        if (open my $fh, '-|', $pkg_config, "--$field", 'fribidi') {
            local $/;
            my $value = <$fh>;
            if (close $fh && defined $value) {
                $value =~ s/\s+\z//;
                $fribidi{$field} = $value;
            }
        }
    }
    %fribidi = () unless exists $fribidi{modversion}
        && exists $fribidi{cflags} && exists $fribidi{libs};
}
if ( %fribidi ) {
    $libs = $fribidi{'libs'};
    $cflags = $fribidi{'cflags'};
    if (version->parse($fribidi{'modversion'}) < version->parse($min_fribidi)) {
        warn <<EOF;
Found an old version of the fribidi library. This version
of Text::Bidi requires fribidi >= $min_fribidi
EOF
        exit 0;
    }
} else {
    unless ( -r '/usr/include/fribidi/fribidi.h' ) {
        warn <<'EOF';

It seems that fribidi is missing. 

fribidi should be installed prior to the installation of this module.

EOF
        exit 0;

    }
    warn "Using heuristic values for CFLAGS and LIBS\n";
    $libs = '-lfribidi';
    $cflags = '-I/usr/include/fribidi';
}

my %PM = ('lib/Text/Bidi/private.pm' => '$(INST_LIB)/Text/Bidi/private.pm');
find(sub {
    if ($File::Find::name =~ m!^lib/(.*\.pm)$!) {
        $PM{$File::Find::name} = '$(INST_LIB)/' . $1;
    }
}, 'lib');

my %WriteMakefileArgs;
##{ use Data::Dumper; $default_args{'NAME'} = 'Text::Bidi::private'; Data::Dumper->Dump([\%default_args], [ '*WriteMakefileArgs' ]) ##}

my $is_release = 0;
##{ '$is_release = 1;' ##}

# Dist::Zilla supplies release metadata; a checkout can also be built directly.
%WriteMakefileArgs = (
    NAME => 'Text::Bidi::private',
    VERSION => '0.00',
    MIN_PERL_VERSION => '5.010000',
    TEST_REQUIRES => { 'Test::More' => 0, 'version' => '0.77' },
    %WriteMakefileArgs,
);

%WriteMakefileArgs = (%WriteMakefileArgs,
    INC => $cflags,
    LIBS => $libs,
    OBJECT => 'private.o',
    PM => \%PM,
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    my $swig = $ENV{SWIG} || 'swig';
    # Tar extraction can make the interface newer than the shipped wrapper.
    # Regenerate automatically in checkouts, and explicitly in releases.
    my $dependency = $is_release ? '' : 'swig/fribidi.i';
    <<EOF;
SWIG = $swig

pm_to_blib: lib/Text/Bidi/private.pm

private.c: $dependency
	\$(SWIG) -perl5 -Wall $cflags -outdir lib/Text/Bidi/ -o private.c swig/fribidi.i

lib/Text/Bidi/private.pm: private.c
	\@test -f \$\@ || \$(SWIG) -perl5 -Wall $cflags -outdir lib/Text/Bidi/ -o private.c swig/fribidi.i

.PHONY: swig
swig:
	\$(SWIG) -perl5 -Wall $cflags -outdir lib/Text/Bidi/ -o private.c swig/fribidi.i
 
swig-clean: clean
	-rm private.c lib/Text/Bidi/private.pm

EOF
}

