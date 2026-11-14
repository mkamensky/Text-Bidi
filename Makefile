.PHONY: all test

all:
	perl Makefile.PL
	$(MAKE)

test:
	perl Makefile.PL
	$(MAKE) test

