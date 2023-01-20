use strict;
use warnings;
use version 0.77;

##{ $perl_prereq ? qq[use $perl_prereq;] : ''; ##}

use ExtUtils::MakeMaker ##{ $eumm_version ##};

my (%fribidi, $libs, $cflags);

my $min_fribidi = '1.0.0';

eval { require ExtUtils::PkgConfig };
if ( $@ ) {
    warn $@;
} else {
    %fribidi = eval { ExtUtils::PkgConfig->find('fribidi') };
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
    $cflags = '-I/usr/include/fribidi -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include';
}

my %PM = map { 'lib/' . $_ => '$(INST_LIB)/' . $_} qw(
Text/Bidi/private.pm
##{
use File::Find;
my $result;
find(sub { $result .= "$1\n" if $File::Find::name =~ m!lib/(.*pm)$! }, 'lib');
$result
##}
);

my ##{
    use Data::Dumper;
    $default_args{'NAME'} = 'Text::Bidi::private';
    Data::Dumper->Dump([\%default_args], [ '*WriteMakefileArgs' ])
    ##}

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
    <<EOF;
pm_to_blib: lib/Text/Bidi/private.pm

private.c lib/Text/Bidi/private.pm: swig/fribidi.i
	/usr/bin/swig -perl -Wall -I/usr/include $cflags -outdir lib/Text/Bidi/ -o private.c \$<
 
swig-clean: clean
	-rm private.c lib/Text/Bidi/private.pm

EOF
}

