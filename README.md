# Btrfs Subvolume Snapshot Utility (version: 1.3.1)

Original source repository: https://github.com/osamuaoki/bss

This script is early development stage and intended for my personal usage.
UI may change.  Use with care.

## `bss` command

Usage: bss [OPTIONS] SUBCOMMAND [PATH [ [ARG]...]

"bss" is basically a "btrfs subvolume ..." command wrapper to create and
process historical snapshots with the intuitive snapshot subvolume name and
flexible data aging capabilities.  (Some subcommands can work with ext2/3/4fs,
too.)

"bss" operates on the btrfs subvolume pointed by the first optional argument
PATH.  PATH can point to anywhere within this source btrfs subvolume.  The
default value for PATH is the current directory (".").  The internal variable
"$FS_BASE" is the BASE directory of this source btrfs subvolume.

"bss snapshot [PATH]" starts "snapshot" operation to create a btrfs readonly
snapshot of the source btrfs subvolume using "btrfs subvolume snapshot -r ...".
The snapshot subvolume is named with ISO 8601 timestamp and TYPE specifier,
e.g.  '2020-09-02T11:51:50+00:00.single' and placed normally in the ".bss.d/"
directory relative to the BASE directory.  This normal mode is intended to be
used for the user data.

"bss snapshot [PATH]" can place its snapshots under the "BSS_SNAP_DEST"
directory specified in ".bss.conf".  Normally, it is set to the null string to
indicate "bss" to use the normal mode.  This "BSS_SNAP_DEST" directory must be
on the same btrfs but it can be outside of the snapshot source subvolume.  This
system mode is intended to be used for the root filesystem.

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
* -c,--conf RC:   use "RC.conf", "RC.fltr" etc. instead of their
                  default ".bss.conf", ".bss.fltr" etc.
* -f,--force:     force to reapply filter
* -n,--noop:      no file nor filesystem modification by prepending pertinent
                  internal commands with "echo __"
* -h,--help:      show this help
* --version:      show version
* -l,--logger:    use systemd logger
* -m,--may:       may execute snapshot or gather if possible
* -q,--quiet:     quiet (no notice messages, just warn/error messages)
* -v,--verbose:   verbose (with info messages)
* -vv:            very verbose for debug (with info and debug messages)
* -x:             trace on (trace shell code for debug)

SUBCOMMAND:

* snapshot: make a readonly snapshot normally in the relative path ".bss.d/"
            as <ISO_8601_date>.<TYPE>  (The default type is "single")
* overview: overview of all snapshots (wrapper for age)
* process:  process snapshots according to their aging status
* copy:     copy subvolume at the BASE directory (1st argument) to the (remote)
            destination (2nd argument) using rsync
* jobs:     list all systemd timer schedule jobs for bss
* list:     list all snapshots
* age:      assess aging status of all snapshots
* gather:   gather files to "gather_root" and "gather_home" based on ".gatherrc"
* filter:   create a filtered snapshot from the specified snapshot in
            ".bss.d/" as <specified_subvol_name>_filter
* revert:   make snapshot <ISO_8601_date>.last and replace the subvolume at the
            BASE directory (1st argument) with the specified snapshot
            <ISO_8601_date>.<extension> (2nd argument) found under
            "BSS_SNAP_DEST" specified in ".bss.conf".  This is only for the
            system mode. (This is alpha stage untested feature.)
* zap:      zap (=delete) particular snapshot(s) specified by the arguments
            "zap" is required to be typed in full text.
* template: make template files in the ".bss.d/" directory:
              ".bss.conf" (aging rule)
              ".bss.fltr" (filtering rule)
* BASE:     print the BASE directory for "bss"

Subcommands may be shortened to a single character.

ARGUMENTS:

For some SUBCOMMANDs, enxtra optional arguments after the explicit PATH may
be specified.

For "bss copy", this is a combination of "bss snapshot" to create a snapshot
of the BASE directory to SOURCE_PATH and a wrapper for "sudo rsync" command with
its first argument SOURCE_PATH and the second argument DEST_PATH.  This command
is smart enough to skip the ".bss.d/" directory to allow independent
management of data using "bss" on both the BASE directory and DEST_PATH. If
DEST_PATH is a local path such as "/srv/backup", then "sudo rsync -aHxS --delete" is
used to save the CPU load.  If DEST_PATH is a remote path such as
"[USER@]HOST:DEST_PATH", then "sudo rsync -aHxSz --delete" is used to save the network
load.

For "bss zap", the first argument is normally ".".  The following argument
specifies the action which can be:

  * new:        zap (=delete) the newest snapshot subvolume
  * old:        zap the oldest snapshot subvolume
  * half:       zap the older half of snapshot subvolumes
  * \<subvolume>…: zap specified snapshot subvolume(s) (path without ".bss.d/")

Unless you have specific reasons to use "bss zap", you should consider to use
"bss process" to prune outdated snapshots.

For "bss revert PATH PATH_OLD", subvolume at PATH is replaced by the subvolume
at PATH_OLD.  PATH can't be set to "/".

For "bss gather [PATH [PREFIX]]", files listed in ".PREFIXrc" are copied into
PREFIX_root and PREFIX_home.  The relative path are interpreted as one from the
user's home directory. The default for PREFIX is "gather".

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

This "bss" calculates age related time values in the second and prints them in
the DAYS.HH:MM:SS format (HH=hour, MM=minute, SS=second).

You can make a snapshot just by "bss" alone.

You can use verbose "bss -v BASE" command to print current effective
configuration parameters without side effects.

This "bss" command uses systemd journal.  You can check recent invocation with:

* $ journalctl -a -b -t bss

CAVEAT:

The source filesystem must be btrfs for many subcommands.

The non-root user who executes this command must be a member of "sudo".

Running filter script ".bss.fltr" drains CPU and SSD resources but it may save
SSD usage size significantly.  If you are not interested in reducing SSD usage
size by this script, remove this ".bss.fltr" file and set
BSS_TMID_ACTION="no_filter" in ".bss.conf".

The "revert" operation is supported only for the system mode.  APT updates can
be used to create snapshots of the system.  The "revert" operation can bring
the system before the APT update operation.  The "revert" operation  must be
performed from the secondary system on another root filesystem and all
subvolumes to be manipulated shouldn't be accessed by other processes. You
should manually mount using "/etc/fstab" for all subvolumes under the subvolume
to run "revert" operation and manage them separately to keep the system
recoverable since the snapshot operation isn't recursive.

Although this "bss" focuses on btrfs, there is minimal support for ext2/ext3
(this includes ext4) for "bss copy ...", "bss gather ...", and "bss
template".

Copyright 2022 Osamu Aoki <osamu@debian.org>, GPL 2+
<!---
vim:se tw=78 ai si sts=4 sw=4 et:
-->
## Note on `revert` operation

This is rather untested experimental feature with limited capabilities.  Use
with care!

## Note on the code design

This `bss` is designed with following consideration:

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
* Move the current working directory to a btrfs managed by `bss`
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
  * Adjust configuration by editing `.bss.d/.bss.conf`
  * Adjust filter by editing `.bss.d/.bss.conf`

### Customization of automatic snapshots of user data

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

### Customization of automatic snapshots of system data

Automatic snapshot of system data in `/` can be enabled using examples in
`/usr/share/doc/bss/examples/etc/apt/apt.conf.d/80bss`.  For these to be
useful, you need to mount the root of the btrfs partion containing `/`
somewhere like `/btrfs/main` and create `@rootfs-snapshots` directory next to
`@rootfs` holding `/`.  Then, in `/.bss.d/.bss.conf` specify,
`BSS_SNAP_DEST="/btrfs/main/@rootfs-snapshots`.

If something goes wrong with the system, make snapshot of `/` and remove
`@rootfs` subvolume and make read-write copy subvolume `@rootfs` from one of
the older snapshot in `/btrfs/main/@rootfs-snapshots`.

## Tips

### Removing many subvolumes by bss

If quota is enabled, removing many subvolumes by bss may cause issues.

### Excluding files from the `snapshot` operation

If you wish to exclude files under a particular directory, simply creating a
pertinent subvolume containing those files in place of the directory allows to
exclude them to be a part of the `snapshot` operation.

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

### Migration of the root filesystem to `subvol=@rootfs` on Btrfs.

See [Btrfs migration](https://wiki.debian.org/Btrfs%20migration)

### Snapshots to an absolute path

For the filesystem containing the system data, such as `@rootfs`, it is easier
to perform recovery operation if its snapshots reside in an absolute path
outside of the original filesystem.  `BSS_SNAP_DEST` variable in
`.bss.d/.bss.conf` can be used to enable it.

### Backup with rsync (USB or remote)

The snapshot mechanism of btrfs offers efficient historical storage but is
never meant to replace full capabilities of the backup mechanism.  For disk
failures, you should rely on data on different storage devices.  The easiest
backup for the consumer grade system is full backup to USB connected SSD.

Although the combination of `btrfs send` with the incremental mode (options
`-p` and `-c`) and `btrfs receive` provides the fast and efficient backup, it
needs to be used carefully.  So for the robustness of backup for a careless
person (i.e., myself), I integrated `rsync` approach to this script as `bss
copy`.

`bss copy` makes readonly snapshot and run `rsync -aHxSv --delete ...`
(H: hardlink, x: one filesystem, S: sparse file ) on it to the specified
destination.

```
 $ bss copy . /media/usb_ssd/userdata
 $ bss copy / /media/usb_ssd/rootfs
```

The backup data may use btrfs on USB connected SSD and you can use `bss` to
manage its history.  In this case, `bss` related files in the `.bss.d/`
directory are protected via `rsync` filter rules so aging on USB connected SSD
can be managed independently.

The destination can be a remote host for bss.  I use rsync.net service now.
bss automatically activates compression for rsync to save the network
bandwidth.

For other cloud storage service, use of `rclone` instead of `rsync` is a
possibility. (patch welcome)

## `luksimg` command

In order to address valid data security concern of storing data on a remote server
administered NOT by oneself, a command `luksimg` is provided as a helper tool to
work easily with LUKS encrypted disk image for storing sensitive data.

Usage: luksimg [-r RSYNC|-s SECRET] [-l|-a] [n [size]|o|m|b|u|c|a]

"luksimg" helps to create and update LUKS encrypted disk image.

OPTION:

-r RSYNC        use '\~/RSYNC/' insted of '\~/rsync/' to place the
                LUKS encrypted disk image file.

-s SECRET       use '\~/rsync/SECRET.img' insted of '\~/rsync/secret.img'
                for the LUKS encrypted disk image file.

-l, --logger    use journald to record log (useful for systemd timer service)

-a, --ask       ask passphrase to unlock LUKS encryption (Unless this is set,
                GNOME secret-tool is used to obtain passphrase)

COMMAND:

Multiple commands may be specified to execute them in sequence.

new [size]:
        make a new sparse disk image '\~/rsync/secret.img' formatted as
        ext4 filesystem on LUKS encrypted volume. The size can be
        optionally specified, e.g. as '32G'
open:   decrypt the LUKS disk image '\~/rsync/secret.img' to create a
        device-mapper device '/dev/device-mapper/secret'
mount:  mount the device-mapper device '/dev/device-mapper/secret' onto
        '\~/rsync/secret.mnt'
backup: backup files specified in '\~/.secretrc' to '\~/secret.mnt/'
umount: umount the device-mapper device '/dev/device-mapper/secret'
        from '\~/secret.mnt/'
close:  close the device-mapper device '/dev/device-mapper/secret'
all:    perform all actions: open -> mount -> backup -> umount -> close

These commands may be shortened if they aren't ambiguous.

See /usr/share/doc/bss/examples/README.md or
    https://github.com/osamuaoki/bss/tree/main/examples

Copyright 2023 Osamu Aoki <osamu@debian.org>, GPL 2+
