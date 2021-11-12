DESTDIR =
prefix = /
#prefix = /usr/local

all:
	: Do nothing

install:
	install        -D usr/bin/bss                                 $(DESTDIR)$(prefix)/usr/bin/bss
	install        -D usr/bin/secret-folder                       $(DESTDIR)$(prefix)/usr/bin/secret-folder
	install -m 644 -D usr/share/bash-completion/completions/bss   $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/bss
	install -m 644 -D usr/share/man/man1/bss.1                    $(DESTDIR)$(prefix)/usr/share/man/man1/bss.1
	install -m 644 -D README.md                                   $(DESTDIR)$(prefix)/usr/share/doc/bss/README
	cp             -a examples/                                   $(DESTDIR)$(prefix)/usr/share/doc/bss/examples/

clean:
	-rm bss.help2man bss.1 bss.1.orig bss.1.old bss.1.rej

distclean: clean

test:
	sh -n usr/bin/bss
	# check version
	if [ -d debian ] && [ -r debian/changelog ]; then \
		U_VER=$$(sed -n -e '/^BSS_VERSION=/s/"//g' \
			-e "/^BSS_VERSION=/s/'//g" \
			-e '/^BSS_VERSION=/s/BSS_VERSION=//p' usr/bin/bss) ; \
		D_VER=$$(dpkg-parsechangelog -S Version) ; \
		if [ "$$U_VER" != "$${D_VER%-*}" ]; then \
			echo "ERROR: fix version in source $$U_VER or debian/changelog  $$D_VER" ; \
			exit 1 ; \
		fi ; \
	fi

#### Since there is no guarantee how help2man output is consistently formatted and
#### it may cause patch to choke, this not-so-robust part of code is outside of
#### normal build since this is just for synchronizing documentation with the
#### script.
prep: test
	-rm README.md bss.1
	$(MAKE) README.md
	$(MAKE) bss.1
	cp -f bss.1 usr/share/man/man1/bss.1
	$(MAKE) clean

README.md:
	echo "<!-- This is auto-generated file.  Edit usr/bin/bss or README.tail and run 'make README.md' -->" > $@
	echo "# Btrfs Subvolume Snapshot Utility (version: $$(usr/bin/bss --version|sed -n -e 's/bss (\(.*\))$$/\1/p' ))" > $@
	echo >>$@
	echo "Original source repository: https://github.com/osamuaoki/bss" >>$@
	echo >>$@
	echo "This script is early development stage and intended for my personal usage.  UI may change.  Use with care.">>$@
	echo >>$@
	echo '## `bss` command' >> $@
	echo >>$@
	usr/bin/bss help | sed -E -e '/^  [^ *]/s/^  /* /' -e '/^[^:]*$$/s/^(\* [^ ]+ ?[^ ]+)  /\1: /' -e 's/…_/…\\_/' -e 's/^  \* <sub/  \* \\<sub/' >>$@
	cat README.tail >>$@
	usr/bin/secret-folder help >>$@

bss.1:
	help2man usr/bin/bss >bss.help2man
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

uninstall:
	-rm -f $(DESTDIR)$(prefix)/usr/bin/bss
	-rm -f $(DESTDIR)$(prefix)/usr/share/bash-completion/completions/bss
	-rm -f $(DESTDIR)$(prefix)/usr/share/man/man1/bss.1
	-rm -rf $(DESTDIR)$(prefix)/usr/share/doc/bss

.PHONY: all install clean distclean test uninstall
