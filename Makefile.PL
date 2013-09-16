use ExtUtils::MakeMaker 6.52;
my (%fribidi, $libs, $cflags);
eval { require ExtUtils::PkgConfig };
if ( $@ ) {
    warn $@;
} else {
    %fribidi = eval { ExtUtils::PkgConfig->find('fribidi') };
}
if ( %fribidi ) {
    $libs = $fribidi{'libs'};
    $cflags = $fribidi{'cflags'};
} else {
    unless ( -r '/usr/include/fribidi/fribidi.h' ) {
        die <<'EOF'
It seems that fribidi is missing. 

fribidi should be installed prior to the installation of this module.

EOF
    }
    warn "Using heuristic values for CFLAGS and LIBS\n";
    $libs = '-lfribidi';
    $cflags = '-I/usr/include/fribidi -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include';
}

WriteMakefile(
    NAME => 'Text::Bidi::private',
    EXE_FILES => ['bin/fribidi.pl'],
    VERSION_FROM => 'lib/Text/Bidi.pm',
    ABSTRACT_FROM => 'lib/Text/Bidi.pm',
    DISTNAME => 'Text-Bidi',
    INC => $cflags,
    LIBS => $libs,
    LICENSE => 'perl',
    AUTHOR => 'Moshe Kamensky <kamensky@cpan.org>',
    MIN_PERL_VERSION => '5.10.0',
    CONFIGURE_REQUIRES => { 'ExtUtils::PkgConfig' => 0,
                            'ExtUtils::MakeMaker' => 6.52, },
    META_MERGE => { no_index => {package => [qw(Text::Bidi::privatec 
                                                Text::Bidi::private)]},
                    keywords => [qw(bidi rtl hebrew arabic)]},
    #OPTIMIZE => '-ggdb3',
    OBJECT => 'private.o',
);

sub MY::postamble {
    <<EOF;
private.c: swig/fribidi.i
	-/usr/bin/swig -perl -Wall -I/usr/include $cflags -outdir lib/Text/Bidi/ -o \$@ \$<

swig-clean: clean
	-rm private.c lib/Text/Bidi/private.pm

EOF
}
