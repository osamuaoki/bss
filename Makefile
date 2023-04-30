DESTDIR =
prefix = /
#prefix = /usr/local


# For finishing

all:
	: Do nothing

install:
	install -m 755 -D usr/bin/bss                                   $(DESTDIR)$(prefix)/usr/bin/bss
	install -d $(DESTDIR)$(prefix)/usr/share/bss
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" < usr/share/bss/common.sh > $(DESTDIR)$(prefix)/usr/share/bss/common.sh
	chown 644 $(DESTDIR)$(prefix)/usr/share/bss/common.sh
	install -m 644 -D usr/share/bash-completion/completions/bss     $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/bss
	install -m 644 -D usr/share/man/man1/bss.1                      $(DESTDIR)$(prefix)/usr/share/man/man1/bss.1
	install -m 755 -D usr/bin/luksimg                               $(DESTDIR)$(prefix)/usr/bin/luksimg
	install -m 644 -D usr/share/bash-completion/completions/luksimg $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/luksimg
	install -m 644 -D usr/share/man/man1/luksimg.1                  $(DESTDIR)$(prefix)/usr/share/man/man1/luksimg.1
	install -m 644 -D README.md                                     $(DESTDIR)$(prefix)/usr/share/doc/bss/README
	cp             -a examples/                                     $(DESTDIR)$(prefix)/usr/share/doc/bss/examples/

#### Run this to clean up source tree
clean:
	-rm bss.help2man bss.1 bss.1.orig bss.1.old bss.1.rej
	-rm luksimg.help2man luksimg.1 luksimg.1.orig luksimg.1.old luksimg.1.rej

distclean: clean

#### Since there is no guarantee how help2man output is consistently formatted and
#### it may cause patch to choke, this not-so-robust part of code is outside of
#### normal build since this is just for s ynchronizing documentation with the
#### script.

# This is used during package build, too.
test:
	# sanity check of shell code
	sh -n usr/bin/bss
	sh -n usr/bin/luksimg
	sh -n usr/share/bss/common.sh

# Run this during development
dev: test usr/share/man/man1/bss.1 usr/share/man/man1/luksimg.1 README.md

usr/share/man/man1/%.1: %.1
	cp -f $< $@

### Run this before commiting.
prep: usr/share/man/man1/bss.1 usr/share/man/man1/luksimg.1 README.md
	$(MAKE) clean

README.md: .FORCE
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
	usr/bin/bss --help | \
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" | \
	sed -E -e '/^  [^ *]/s/^  /* /' -e '/^[^:]*$$/s/^(\* [^ ]+ ?[^ ]+)  /\1: /' -e 's/…_/…\\_/' -e 's/^  \* <sub/  \* \\<sub/' >>$@
	cat README.tail >>$@
	usr/bin/luksimg --help | \
	sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" | \
	sed -e "s/\~/\\\~/g" >>$@

.FORCE:

bss.1: .FORCE
	if ! type help2man >/dev/null ; then echo "install 'help2man' package" ; fi
	help2man usr/bin/bss | sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" >bss.help2man
	sed -E -e 's/^([A-Z]*):$$/.SH \1/' \
	       -e 's/bss \\- manual page for bss/bss \\- btrfs subvolume snapshot utility/' \
	       bss.help2man | \
	sed -E -e '/^\.SH COPYRIGHT/,$$ d' >bss.1
	cat bss.1.tail >> bss.1
	: ===============================================================================
	: = If this fails, do the following:                                            =
	: =  * get the older working version by 'cp usr/share/man/man1/bss.1 bss.1.old' =
	: =  * fix bss.1 by editing as 'vimdiff bss.1 bss.1.old'                        =
	: =  * update bss.1.patch using 'diff -u bss.1.orig bss.1 > bss.1.patch'        =
	: ===============================================================================
	patch bss.1 <bss.1.patch
	: ===============================================================================
	: = Successfully updated                                                        =
	@if [ -r bss.1.orig ]; then \
	echo ": =   Fuzz found, update bss.1.patch.                                           =" ; \
	diff -u bss.1.orig bss.1 >bss.1.patch || true; \
	else \
	echo ": = No fuzz found.                                                              =" ; \
	fi
	: ===============================================================================

luksimg.1: .FORCE
	if ! type help2man >/dev/null ; then echo "install 'help2man' package" ; fi
	help2man usr/bin/luksimg | sed -e "s/@@@VERSION@@@/$$(dpkg-parsechangelog -S Version)/" >luksimg.help2man
	sed -E -e 's/^([A-Z]*):$$/.SH \1/' \
	       -e 's/luksimg \\- manual page for luksimg/luksimg \\-  LUKS encrypted disk image utility/' \
	       luksimg.help2man | \
	sed -E -e '/^\.SH COPYRIGHT/,$$ d' >luksimg.1
	cat luksimg.1.tail >> luksimg.1
	: ===============================================================================
	: = If this fails, do the following:                                            =
	: =  * get the older working version by 'cp usr/share/man/man1/luksimg.1 luksimg.1.old' =
	: =  * fix luksimg.1 by editing as 'vimdiff luksimg.1 luksimg.1.old'                        =
	: =  * update luksimg.1.patch using 'diff -u luksimg.1.orig luksimg.1 > luksimg.1.patch'        =
	: ===============================================================================
	patch luksimg.1 <luksimg.1.patch
	: ===============================================================================
	: = Successfully updated                                                        =
	@if [ -r luksimg.1.orig ]; then \
	echo ": =   Fuzz found, update luksimg.1.patch.                                           =" ; \
	diff -u luksimg.1.orig luksimg.1 >luksimg.1.patch || true; \
	else \
	echo ": = No fuzz found.                                                              =" ; \
	fi
	: ===============================================================================

uninstall:
	-rm -f $(DESTDIR)$(prefix)/usr/bin/bss
	-rm -f $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/bss
	-rm -f $(DESTDIR)$(prefix)/usr/share/man/man1/bss.1
	-rm -f $(DESTDIR)$(prefix)/usr/bin/luksimg
	-rm -f $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/luksimg
	-rm -f $(DESTDIR)$(prefix)/usr/share/man/man1/luksimg.1
	-rm -rf $(DESTDIR)$(prefix)/usr/share/doc/bss

.PHONY: all install clean distclean test uninstall
