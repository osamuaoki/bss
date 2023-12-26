# vim:set noet ts=8 sts=8 sw=8:
DESTDIR =
prefix = /
#prefix = /usr/local

### When updating this source, update command first.  Manpage and README.md
### are updated using "make prep".

#############################################################################
# These targets are used during package build.
#############################################################################
all:
	: # do nothing (it's a script system)

install:
	install -m 755 -D usr/bin/bss                                   $(DESTDIR)$(prefix)/usr/bin/bss
	install -d $(DESTDIR)$(prefix)/usr/share/bss
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" < usr/share/bss/common.sh > $(DESTDIR)$(prefix)/usr/share/bss/common.sh
	chown 644 $(DESTDIR)$(prefix)/usr/share/bss/common.sh
	install -m 644 -D usr/share/bss/log.sh                          $(DESTDIR)$(prefix)/usr/share/bss/log.sh
	install -m 644 -D usr/share/bash-completion/completions/bss     $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/bss
	install -m 644 -D usr/share/man/man1/bss.1                      $(DESTDIR)$(prefix)/usr/share/man/man1/bss.1
	install -m 755 -D usr/bin/luksimg                               $(DESTDIR)$(prefix)/usr/bin/luksimg
	install -m 644 -D usr/share/bash-completion/completions/luksimg $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/luksimg
	install -m 644 -D usr/share/man/man1/luksimg.1                  $(DESTDIR)$(prefix)/usr/share/man/man1/luksimg.1
	install -m 644 -D README.md                                     $(DESTDIR)$(prefix)/usr/share/doc/bss/README
	cp             -a examples/                                     $(DESTDIR)$(prefix)/usr/share/doc/bss/examples/

#### Run this to clean up source tree
clean:
	-rm -f bss.1.orig bss.1.old bss.1.rej bss.1.base bss.pre*
	-rm -f luksimg.1.orig luksimg.1.old luksimg.1.rej luksimg.1.base luksimg.pre*

distclean: clean

uninstall:
	-rm -f $(DESTDIR)$(prefix)/usr/bin/bss
	-rm -f $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/bss
	-rm -f $(DESTDIR)$(prefix)/usr/share/man/man1/bss.1
	-rm -f $(DESTDIR)$(prefix)/usr/bin/luksimg
	-rm -f $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/luksimg
	-rm -f $(DESTDIR)$(prefix)/usr/share/man/man1/luksimg.1
	-rm -rf $(DESTDIR)$(prefix)/usr/share/doc/bss

test:
	# sanity check of shell code
	sh -n usr/bin/bss
	sh -n usr/bin/luksimg
	sh -n usr/share/bss/common.sh

.PHONY: all install clean distclean test uninstall
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
	$(MAKE) luksimg.1
	$(MAKE) usr/share/man/man1/bss.1 usr/share/man/man1/luksimg.1
	$(MAKE) README.md

%.help2man: FORCE
	if ! type help2man >/dev/null ; then echo "install 'help2man' package" ; fi
	help2man usr/bin/$* > $@

%.1.base: %.help2man
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" \
	    -e 's/^\([A-Z]*\):$$/.SH \1/' \
	    -e 's/bss \\- manual page for bss/$* \\- btrfs subvolume snapshot utility/' \
	    -e 's/luksimg \\- manual page for luksimg/luksimg \\-  LUKS encrypted disk image utility/' \
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

bss.pre0: FORCE
	usr/bin/bss --help > $@

luksimg.pre0: FORCE
	usr/bin/luksimg --help > $@

%.pre1: %.pre0
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" $< > $@

%.pre2: %.pre1
	# make list in markdown for "  " starting lines
	sed -e '/^  [^ *]/s/^  /* /' $< >$@

%.pre3: %.pre2
	# add ":" before first "  " in list
	sed -e '/^\*/s/^\(\*.*\)  \(.*\)$$/\1: \2/' -e '/^\*/s/ *:/:/' $< >$@

%.pre4: %.pre3
	# trim long leading spaces
	sed -e '/^      *\*/s/^[ ]*\*/  \* /' $< >$@

%.pre5: %.pre4
	# escape special characters
	sed -e 's,~,\\~,g' -e 's,<,\\<,g'  $< >$@

README.md: FORCE
	$(MAKE) bss.pre5 luksimg.pre5
	echo "<!-- This is auto-generated file.  Edit usr/bin/bss or README.tail and run 'make README.md' -->" > $@
	echo "# Btrfs Subvolume Snapshot Utility (version: $$(dpkg-parsechangelog -S Version))" > $@
	echo >>$@
	echo "Original source repository: https://github.com/osamuaoki/bss" >>$@
	echo >>$@
	echo "This script is early development stage and intended for my personal usage.">>$@
	echo "UI may change.  Use with care.">>$@
	echo >>$@
	echo '## `bss` command' >> $@
	echo >>$@
	cat bss.pre5 >> $@
	cat README.tail >>$@
	cat luksimg.pre5 >> $@

#############################################################################
# These targets must be used only before package build to fix *.patch.
#############################################################################

.PHONY: patch

# run this when resulting bss.1 or luksimg.1 are manually updated
patch: bss.1.patch luksimg.1.patch

%.1.patch: FORCE
	if [ -r "$*.1.base" ] || [ -r "$*.1" ]; then \
		diff -u $*.1.base $*.1 >$*.1.patch || true ; else \
		echo "No patch generated for $*.1.patch"; fi
.PHONY: FORCE
FORCE:
