CFLAGS = $(shell pkg-config --cflags fribidi)
SWIG ?= swig

private.c: swig/fribidi.i
	$(SWIG) -perl5 -Wall $(CFLAGS) -outdir lib/Text/Bidi/ -o $@ $<

lib/Text/Bidi/private.pm: private.c
	@test -f $@ || $(SWIG) -perl5 -Wall $(CFLAGS) -outdir lib/Text/Bidi/ -o private.c swig/fribidi.i

