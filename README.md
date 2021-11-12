# Btrfs Subvolume Snapshot Utility (version: 1.0.0)

Original source repository: https://github.com/osamuaoki/bss

This script is early development stage and intended for my personal usage.  UI may change.  Use with care.

## `bss` command

Usage: bss [OPTIONS] SUBCOMMAND [PATH [[ARG]...]

"bss" is basically a "btrfs subvolume ..." command wrapper to create and
process historical snapshots with the intuitive snapshot subvolume name and
flexible data aging capabilities.

"bss" operates on the btrfs subvolume pointed by the first optional argument
PATH.  PATH can point to anywhere within the targeted btrfs subvolume.  The
default value for PATH is the current directory (".").  The internal variable
"$BTRFS_BASE" is the BASE directory of this target btrfs subvolume.

"bss snapshot [PATH]" starts "snapshot" operation to create a btrfs readonly
snapshot of the target btrfs subvolume using "btrfs subvolume snapshot -r ...".
The snapshot subvolume is named with ISO 8601 timestamp and TYPE specifier,
e.g.  '2020-09-02T11:51:50+00:00.single' and placed in the ".bss.d/"
directory under the BASE directory.

"bss process [PATH]" starts "process" operation to process existing snapshots
generated by "bss" according to their age.  "bss" checks the time interval
between them from the older ones to newer ones and makes them more sparse for
the older ones by removing some of them using parameters in ".bss.conf" in the
".bss.d/" directory.  This involves following actions:

  * Secure minimum required free blocks (minimum FMIN %).
  * Keep initial few (NMIN) snapshots unconditionally.
  * Limit the maximum number of snapshots to NMAX.
    * NMAX=0 is the special case and means no limit for number of snapshots.
  * Before TMIN, keep snapshots unconditionally.
  * Age snapshots with basically exponentially growing intervals with the
    specified ratio (STEP 2%-90%).
  * After TMID, age snapshots more aggressively.
    * Special handlings to keep some high priority snapshots stop.
    * If TMID_ACTION=filter, content files of snapshots are filtered with the
      script ".bss.fltr" at the ".bss.d/" directory.
  * After TMAX, stop aging snapshots.
    * TMAX=0 is the special case and means no limit for aging.
    * If TMAX_ACTION=drop, drop subvolume after TMAX.
    * If TMAX_ACTION=keep, keep subvolume after TMAX.

OPTIONS:

* -t,--type TYPE: use TYPE instead of the default "single" for the snapshot
                  type.  The automatic snapshot uses "pre" (before APT), "post"
                  (after APT), "hour" (on boot and every hour).
                  If "keep" is specified, the snapshot with it will be
                  kept forever under the normal aging process.
* -c,--conf RC:   use "RC.conf" and "RC.fltr" instead of their
                  default ".bss.conf" and ".bss.fltr"
* -f,--force:     force to reapply filter
* -n,--noop:      no file nor filesystem modification by prepending pertinent
                  internal commands with "echo __"
* -h,--help:      show this help
* --version:      show version
* -l,--logger:    use systemd logger
* -q,--quiet:     quiet (no notice messages, just warn/error messages)
* -v,--verbose:   verbose (with info messages)
* -vv:            very verbose for debug (with info and debug messages)
* -x:             trace on (trace shell code for debug)

SUBCOMMAND:

* snapshot: make a readonly snapshot in ".bss.d/" as
            <ISO_8601_date>.<TYPE>  (The default type is "single")
* overview: overview of all snapshots (wrapper for age)
* process:  process snapshots according to their aging status
* copy:     copy to (remote) destination using rsync
* jobs:     list all systemd timer schedule jobs for bss
* list:     list all snapshots
* age:      assess aging status of all snapshots
* base:     print the BASE directory for "bss"
* filter:   create a filtered snapshot from the specified snapshot in
            ".bss.d/" as <specified_subvol_name>_filter
* revert:   revert contents of the BASE directory from the specified snapshot
            in ".bss.d/" while making snapshots <ISO_8601_date>.last and
            <ISO_8601_date>.<specified_subvol_date>_revert
            (This is alpha stage untested feature.)
* zap:      zap (=delete) particular snapshot(s) specified by ARG(s)
            "zap" is required to be typed in full text.
* template: make template files in the ".bss.d/" directory:
              ".bss.conf" (aging rule)
              ".bss.fltr" (filtering rule)

Subcommands may be shortened to a single character.

ARGUMENTS:

For some SUBCOMMANDs, an enxtra optional argument after the explicit PATH may
be specified to identify the specific snapshot subvolume.

For "bss copy", this is a wrapper for "rsync" command with its first argument
SOURCE_PATH and the second argument TARGET_PATH.  This command is smart enough
to skip the ".bss.d/" directory to allow independent management of data on
the target using "bss".  If TARGET_PATH is a local path such as /srv/backup,
then "rsync -aHxSv --delete" is used to save the CPU load.  If TARGET_PATH
is a remote path such as "[USER@]HOST:DEST", then "rsync -aHxSzv --delete"
is used to save the network load.

For "bss zap", the first argument is normally ".".  The following argument
is the action target specifier which can be:

  * new:        zap the newest snapshots
  * old:        zap the oldest snapshots
  * half:       zap the older half of snapshots
  * \<subvolume>…: zap specified snapshot subvolume(s) (path without ".bss.d/")

Unless you have specific reasons to use "bss zap", you should consider to use
"bss process" to prune outdated snapshots.

NOTE:

This "bss" command comes with examples for systemd scripts and apt hook script
to enable automatic "snapshot" operations.  This "bss" command also comes with
examples for systemd scripts to enable automatic daily "process" operation.

For some snapshots, different TYPE values may be used instead of TYPE='single'.

  * TYPE='pre':  automatic "snapshot" operation just before APT update
  * TYPE='post': automatic "snapshot" operation just after  APT update
  * TYPE='copy': automatic "snapshot" operation just before "bss copy"
  * TYPE='hour': automatic "snapshot" operation on boot and every hour
  * TYPE='last': automatic "snapshot" operation just before "bss revert"
  * TYPE='…\_revert': automatic "snapshot" operation just after "bss revert"

This "bss" calculates age related time values in the second and prints them in
the DAYS.HH:MM:SS format (HH=hour, MM=minute, SS=second).

You can make a snapshot just by "bss" alone.

You can use verbose "bss -v base" command to print current effective
configuration parameters without side effects.

This "bss" command uses systemd journal.  You can check recent invocation with:

* $ journalctl -a -b -t bss

CAVEAT:

The non-root user who executes this command must be a member of "sudo".
PATH in "bss revert PATH" command can't be set to "/".

Running filter script ".bss.fltr" drains CPU and SSD resources but it may save
SSD usage size significantly.  If you are not interested in reducing SSD usage
size by this script, remove this ".bss.fltr" file and set
BSS_TMID_ACTION="no_filter" in ".bss.conf"

In order to use "revert" operation, you may need to dual boot the system from
another root filesystem and must make sure the target subvolume isn't accessed
by other processes by mounting it to somewhere safe.

Copyright 2022 Osamu Aoki <osamu@debian.org>, GPL 2+
<!---
vim:se tw=78 ai si sts=4 sw=4 et:
-->
## Note on "revert" operation

This is rather untested experimental feature with limited capabilities.  Use
with care!

## Note on the code design

This "bss" is designed with following consideration:

* Make package simple and small but powerful and configurable.
  * Use plain POSIX-shell
  * Configurable aging timing.
  * Configurable file filtering.
  * Prevention safeguard for the filling up of btrfs.
  * Capability to limit number of snapshots by number or age.
  * Logging to syslog is available (-l).
  * Easy monitoring of its internal actions (-v and -vv).
  * Snapshots have identifiable names (more like `timeshift`)
  * Offer CLI (more like `snapper`).
  * Accept shortened subcommands.
  * Use UT (+00:00) for code simplicity
  * Use STDOUT for data and STDERR for internal state for consistency.
* Support snapshot of any target btrfs data.
  * No requirement to make the root filesystem as `subvol=@`.
  * Automatic snapshots via systemd timer examples.
  * Automatic pre and post package installation snapshots examples
    via APT operations on Debian/Ubuntu/... system.
  * Automatic aging via systemd examples.
  * Manual snapshot by `bss snap <PATH>`.
  * Manual process data according to their age by `bss process <PATH>`.

## Note on installation

### For Debain/Ubuntu system (latest)

```
 $ git clone https://github.com/osamuaoki/bss.git
 $ cd bss
 $ debuild
 $ cd ..
 $ sudo dpkg -i bss_1.0.0_amd64.deb
```

### For other system

```
 $ git clone https://github.com/osamuaoki/bss.git
 $ cd bss
 $ sudo make install
```

## Getting started

### Basics

* Install bss Debian package
* Move the current working directory to a btrfs managed by "bss"
* Get help with `bss h`.
* Manually create a snapshot with `bss s` or just by `bss`
* Manually process snapshots with `bss p`
* Check existing snapshots with `bss l`.
* Check aging status of existing snapshots with `bss o`.
* Check automatic jobs with `bss j`.
* Manipulate non-current directory by providing PATH after subcommands.

Use of `-v` option gives verbose information.

### Customization of aging behavior

* Create template configuration and filter by `bss t`
  * Adjust configuration by editing ".bss.d/.bss.conf"
  * Adjust filter by editing ".bss.d/.bss.conf"

### Customization of automatic snapshots

Automatic snapshot supports can be set up from the user account using files in
`~/.config/systemd/.config/systemd/user/`. There are some example files under
`/usr/share/doc/bss/examples/`:

```
 $ mkdir -p ~/.config/systemd/user/
 $ cd /usr/share/doc/bss/examples/.config/systemd/user/
 $ cp * ~/.config/systemd/user/
 $ systemctl --user enable bss-hour.timer bss-day.timer
 $ cd /usr/share/doc/bss/examples/.config/autostart/
 $ mkdir -p ~/.config/autostart/
 $ cp * ~/.config/autostart/
 $ mkdir -p ~/bin
 $ cd /usr/share/doc/bss/examples/bin/
 $ cp * ~/bin/
```
After doing all these, please reboot the system.

Use `journalcrl -a -b -t bss` to see its log.

(/usr/share/doc/bss/examples/etc/ has APT automatic snapshot example which I
don't use now)

## Tips

### Removing many subvolumes by bss

If quota is enabled, removing many subvolumes by bss may cause issues.

### Excluding files from the "`snapshot`" operation

If you wish to exclude files under a particular directory, simply creating a
pertinent subvolume containing those files in place of the directory allows to
exclude them to be a part of the "`snapshot`" operation.

### Database file and CoW issue

Please consider to set 'no copy on write' (C) attribute recursively on the
directory prior to placing files such as the database file in it.  For
example:

```
 $ sudo chattr -R +C /var/lib/mysql
```

I suppose that you need to stop database program before making snapshot/backup
of the filesystem containing it.

Maybe the same goes with the actively used disk image file.

### Migration of the root filesystem to `subvol=@` on Btrfs.

See [Btrfs migration](https://wiki.debian.org/Btrfs%20migration)

### Backup with rsync (USB or remote)

The snapshot mechanism of btrfs offers efficient historical storage but is
never meant to replace full capabilities of the backup mechanism.  For disk
failures, you should rely on data on different storage devices.  The easiest
backup for the consumer grade system is full backup to USB connected SSD.

Although the combination of `btrfs send` with the incremental mode (options
`-p` and `-c`) and `btrfs receive` provides the fast and efficient backup, it
needs to be used carefully.  So for the robustness of backup for a careless
person (i.e., myself), I integrated `rsync` approach to this script as "bss
copy".

"bss copy" makes readonly snapshot and run "rsync -aHxSv --delete ..."
(H: hardlink, x: one filesystem, S: sparse file ) on it to the specified
destination.

```
 $ bss copy / /media/usb_ssd/root
 $ bss copy ~ /media/usb_ssd/userdata
```

The backup data may use btrfs on USB connected SSD and you can use `bss` to
manage its history.  In this case, `bss` related files in the ".bss.d/"
directory are protected via `rsync` filter rules so aging on USB connected SSD
can be managed independently.

The destination can be a remote host for bss.  I use rsync.net service now.
bss automatically activates compression for rsync to save the network
bandwidth.

For other cloud storage service, use of `rclone` instead of `rsync` is a
possibility. (patch welcome)

## `secret-folder` command

In order to address data security concern of the use of a remote server
administered NOT by oneself, a helper command to create and work with
encrypted disk image is provided as `secret-folder`.

Usage: secret-folder [new [size]|mount|keep|update|systemd|ask]

"secret-folder" helps to create and update encrypted disk image.

COMMAND:

  * new [size]: make a new disk image of specified size.
                Optional size can be specified as '32G'.
  * mount:      mount disk image ~/rsync/secret.img to ~/secret
  * keep:       don't unmount when exiting secret-folder
                (default behavior is unmount on exit)
  * update:     mount disk image and update its content by copying files and
                directories listed in ~/.secretrc.
  * systemd:    run from systemd timer unit in background while recording log to
                journald.
  * ask:        ask passphrase to unlock LUKS encryption
                (unless this is set, GNOME secret-tool is used to obtain
                passphrase)

These commands may be shortened to a single character.

See /usr/share/doc/bss/examples/README.md or
    https://github.com/osamuaoki/bss/tree/main/examples

Copyright 2022 Osamu Aoki <osamu@debian.org>, GPL 2+
