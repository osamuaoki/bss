# vim:set noet ts=8 sts=8 sw=8:
DESTDIR =
prefix ?= /local

### When updating this source, update command first.  Manpage and README.md
### are updated using "make prep".

#############################################################################
# These targets are used during package build.  (assume prep is done)
#############################################################################
all:
	test "$$(head -n 2 README.md | sed -n -e "/^version: /s/version: //p")" = "$$(dpkg-parsechangelog -S Version)"
	test "$$(sed -n -e "/^.TH/s/^[^(]*(\([^)]*\)).*$$/\1/p" bss.1)" =         "$$(dpkg-parsechangelog -S Version)"
	: source is ready for building deb package

bininstall:
	install -m 755 -d $(DESTDIR)/usr$(prefix)/bin
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" < bin/bss > $(DESTDIR)/usr$(prefix)/bin/bss
	chmod 755 $(DESTDIR)/usr$(prefix)/bin/bss

binuninstall:
	-rm -f $(DESTDIR)/usr$(prefix)/bin/bss

install: bininstall
	install -m 644 -D share/bash-completion/completions/bss     $(DESTDIR)/usr$(prefix)/share/bash-completion/completions/bss
	install -m 644 -D bss.1                                     $(DESTDIR)/usr$(prefix)/share/man/man1/bss.1
	install -m 644 -D README.md                                 $(DESTDIR)/usr$(prefix)/share/doc/bss/README.md
	install -m 644 -D bss_tips.md                               $(DESTDIR)/usr$(prefix)/share/doc/bss/bss_tips.md
	install -m 644 -D bss_tutorial.md                           $(DESTDIR)/usr$(prefix)/share/doc/bss/bss_tutorial.md
	cp             -a examples                                  $(DESTDIR)/usr$(prefix)/share/doc/bss/

#### Run this to clean up source tree
clean:
	-rm -f README.pre*
	-rm -f bss.1.orig bss.1.old bss.1.rej bss.1.base bss.pre*

distclean: clean

uninstall:
	-rm -f $(DESTDIR)/usr$(prefix)/bin/bss
	-rm -rf $(DESTDIR)/usr$(prefix)/share/doc/bss

test:
	# sanity check of shell code
	sh -n bin/bss

.PHONY: all ibininstall install clean distclean test uninstall
#############################################################################
# These targets must be used only before package build.
#############################################################################

.SECONDARY:

.PHONY: prep

#### Since there is no guarantee how help2man output is consistently formatted and
#### it may cause patch to choke, this not-so-robust part of code is outside of
#### normal build since this is just for synchronizing documentation with the
#### script.

#### Run "make prep" and commit successful results to the git repo in advance.

prep:
	$(MAKE) test
	$(MAKE) bss.1
	$(MAKE) README.md

# auto-generate man page
%.help2man: bin/bss
	if ! type help2man >/dev/null ; then echo "install 'help2man' package" ; fi
	help2man bin/$* > $@

%.1.base: %.help2man debian/changelog
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" \
	    -e 's/^\([A-Z]*\):$$/.SH \1/' \
	    -e 's/bss \\- manual page for bss/$* \\- btrfs subvolume snapshot utility/' \
	    -e '/^\.SH COPYRIGHT/,$$ d' $< > $@
	cat $*.1.tail >> $@

%.1: %.1.base
	cp $< $@
	: ===============================================================================
	: = If this fails, do the following:                                            =
	:   * fix $*.1 by editing as 'vi $*.1'
	:   * use older version as reference at 'usr/share/man/man1/$*.1'
	:   * update $*.1.patch using 'make $*.1.patch'
	: ===============================================================================
	if [ -r "$*.1.patch" ]; then patch $@ <$*.1.patch ; fi
	: ===============================================================================
	: = Successfully updated                                                        =
	@if [ -r $*.1.orig ]; then \
	echo ":   * Fuzz found, update $*.1.patch." ; \
	diff -u $*.1.orig $*.1 >$*.1.patch || true; \
	else \
	echo ":   * No fuzz found." ; \
	touch $*.1.patch ; \
	fi
	: ===============================================================================

usr/share/man/man1/%.1: %.1
	cp -f $< $@

###########################################################################################
README.pre0: bin/bss
	bin/bss --help > $@

%.pre1: %.pre0
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" $< > $@

%.pre2: %.pre1
	# make subsection titles
	sed -e 's/^\(\S*\):$$/### \1/' $< >$@

%.pre3: %.pre2
	# make list in markdown for "  " starting lines
	sed -e '/^  [^ *]/s/^  /* /' $< >$@

%.pre4: %.pre3
	# add ":" before first "  " in list
	sed -e '/^\*/s/^\(\*.*\)  \(.*\)$$/\1: \2/' -e '/^\*/s/ *:/:/' $< >$@

%.pre5: %.pre4
	# trim long leading spaces
	sed -e '/^      *\*/s/^[ ]*\*/  \* /' $< >$@

%.pre6: %.pre5
	# escape special characters
	sed -e 's,~,\\~,g' -e 's,<,\\<,g'  $< >$@

README.md: README.md0 README.pre6 README.md1 debian/changelog
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" README.md0 > $@
	cat README.pre6 >> $@
	cat README.md1 >> $@

#############################################################################
# These targets must be used only before package build to fix *.patch.
#############################################################################

.PHONY: patch

# run this when resulting bss.1 is manually updated
patch: bss.1.patch

%.1.patch: FORCE
	if [ -r "$*.1.base" ] || [ -r "$*.1" ]; then \
		diff -u $*.1.base $*.1 >$*.1.patch || true ; \
		echo "patch updated for $*.1.patch" ; else \
		echo "No patch generated for $*.1.patch"; fi
.PHONY: FORCE
FORCE:
