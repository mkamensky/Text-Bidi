CFLAGS = $(shell pkg-config --cflags fribidi)

private.c: swig/fribidi.i
	-/usr/bin/swig -perl -Wall -I/usr/include $(CFLAGS)  -outdir lib/Text/Bidi/ -o $@ $<

