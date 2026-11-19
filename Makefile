.PHONY: all test

all:
	perl Makefile.PL
	$(MAKE) pure_all manifypods

test: all
	$(MAKE) test

