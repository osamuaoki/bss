<!--
version: 2.2.2

vim:set ai si sts=2 sw=2 et tw=79:

* 'README.md' is auto-generated file
* Edit usr/bin/bss, README.md? and run 'make README.md'
-->
# "Btrfs Subvolume Snapshot" utility

This is Osamu's "Btrfs Subvolume Snapshot" utility `bss` which is a shell
wrapper program to execute `btrfs subvolume snapshot` command with required
arguments to manage data on btrfs.  This `bss` is also a shell wrapper program
to execute `rsync` with required arguments containing `-rx` to make backups of
the subvolume.

* [bss: source repository](https://github.com/osamuaoki/bss) -- version: 2.2.2

## Breaking changes

This `bss` script is still in the early development stage and intended only for
my personal usage.

* 2.1.1: Add "bss gather" to use "rsync --files-from" (2024-01-13)
* 2.2.1: Change "bss gather" to use rsync FILTER RULES (2024-03-25)
* 2.2.2: No more exclusive run check inside of bss (2025-08-23)

## Design of `bss`

In order to be absolutely sure to recover from accidental erase of important
data, disastrous disk failure, or even loss of the workstation, this `bss`
command is designed with following items in mind:

* Keep it simple
  * single file shell script
  * simple to configure via batch files `~/.config/bss/*` etc.
  * automatic and easy to execute (integration via `*.desktop` and
    `systemd.unit`(5) files)
  * flexible (no special subvolume name required: `@` or `@rootfs`)
* Offer all basic features
  * enable snapshots on the local disk with time stamp
  * enable aging and processing of older snapshots
  * enable easy backups to the plug-in USB storage
  * enable secure backups to the remote storage service (rsync.net)
* Offer robust data recovery capability
  * rely only on standard backend tools
    * `systemd`
    * Linux kernel (btrfs support)
    * `btrfs-progs`
    * `openssh-client`
    * `rsync`
    * `gnupg`
    * `tar`
    * `libsecret-tools` (Gnome)

## Quick Guide to `bss`

System backup and snapshot tasks can be performed automatically by the system
timer and mount events using their associated systemd unit files or easily by
clicking the GUI icon using its associated desktop file.

Please read the followings:

* [Debian Reference: 10.2. Backup and
  recovery](https://www.debian.org/doc/manuals/debian-reference/ch10.en.html#_backup_and_recovery)
  -- generic concepts
* [bss: Tutorial 1](bss_tutorial1.md) -- for a basic Debian system on ext4
* [bss: Tutorial 2](bss_tutorial2.md) -- for an advanced Debian system on btrfs

Please read these to get started for the backup and snapshot with `bss`.  These
cover practical use cases with examples.

When customizing this baseline configuration, `bss` is designed not to
contaminate command name space and configuration files are mostly localized in
`~/.config/bss/`, `~/.config/systemd/user/` or the root of the target
subvolume.

You can manually run `bss` command directly from the command line as:

```
 $ bss snapshot /path/to/sobvol # make snapshot
 $ bss gather   /path/to/sobvol # gather files and directories
 $ bss overview /path/to/subvol # observe the aging status
 $ bss process  /path/to/subvol # process snapshots according to the aging status
 $ bss template /path/to/subvol # make configuration files
 $ bss jobs     /path/to/subvol # check scheduled bss systemd jobs
 $ bss copy     /path/to/subvol /path/to           # make snapshot and rsync to /path/to
 $ bss copy     /path/to/subvol user@host.dom:foo  # make snapshot and rsync to user@host.dom:foo
 $ bss batch    batchname       # execute shell script in ~/.config/bss/batchname 
 $ bss help                     # command help
```
Please note that the subcommand of `bss` can be shortened to a single character.


## Command reference: `bss`


### USAGE
* bss [OPTIONS] SUBCOMMAND [PATH [ [ARG]...]
* bss SUBCOMMAND [OPTIONS] [PATH [ [ARG]...]

"bss" is basically a "btrfs subvolume ..." command wrapper to create and
process historical snapshots with the intuitive snapshot subvolume name and
flexible data aging capabilities.

"bss" operates mostly on the btrfs subvolume pointed by the first optional
argument "PATH".  "PATH" can point to anywhere within this source btrfs
subvolume.  The default value for "PATH" is the current working directory (".")
when it is missing.  The internal variable "$FS_BASE" is the BASE directory of
this source btrfs subvolume.  (The use of tailing "/" in "PATH" is
insignificant and deprecated.)

"bss snapshot [PATH]" starts "snapshot" operation to create a btrfs readonly
snapshot of the source btrfs subvolume using "btrfs subvolume snapshot -r ...".
The snapshot subvolume is named with ISO 8601 timestamp and TYPE specifier,
e.g.  '2020-09-02T11:51:50+00:00.single' and placed normally in the ".bss.d/"
directory relative to the "$FS_BASE" directory since BSS_SNAP_DEST" specified
in ".bss.conf" is null string.  This normal snapshot mode is intended to be
used for the user data.

"bss snapshot [PATH]" can place its snapshots outside of the "$FS_BASE"
directory by specifying "BSS_SNAP_DEST" in ".bss.conf" to point to somewhere on
the same btrfs but outside of the "$FS_BASE" directory.  This system snapshot
mode is intended to be used for the system data.

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

Subcommands such as "bss copy ...", "bss gather ..." which use "rsync" as
their backend tool work with non-btrfs filesystem.

### OPTIONS

* -t,--type TYPE: use TYPE instead of the default "single" for the snapshot
                  type.  If $BSS_TYPE is exported to bss, its value is used
                  as the default for TYPE instead. The automatic snapshot uses
                  "pre" (before APT), "post (after APT), "snap" (on systemd
                  timer), etc.. If "keep" is specified, the snapshot with it
                  will be kept forever under the normal aging process.
* -c,--conf RC: use "RC.conf", "RC.fltr" etc. instead of their
                  default ".bss.conf", ".bss.fltr" etc.
* -f,--force: force to reapply filter
* -n,--noop: no file nor filesystem modification by prepending pertinent
                  internal commands with "echo __"
* -h,--help: show this help
* --version: show version
* -e,--echo: enable screen echo (default)
* -E,--noecho: disable screen echo (default for bss under batch)
* -l,--logger: enable systemd logger (default for active subcommands)
* -L,--nologger: disable systemd logger (default for passive subcommands)
* -m,--may: may execute snapshot or gather if possible
* -q,--quiet: quiet (no notice messages, just warn/error messages)
* -v,--verbose: verbose (with info messages)
* -vv: very verbose for debug (with info and debug messages)
* -x: trace on (trace shell code for debug)

### SUBCOMMAND

* snapshot: make a readonly snapshot normally in the relative path ".bss.d/"
             as "\<ISO_8601_date>.\<TYPE>"  (The default type is "single")
* list: list all snapshots
* age: assess aging status of all snapshots
* overview: overview of all snapshots (wrapper for "bss -v age >/dev/null")
* process: process snapshots according to their aging status
* copy: copy subvolume at the BASE directory (1st argument) to the
             (remote) destination (2nd argument) using rsync
* gather: gather listed local files in configuration files to the
             ".gather.dir" directory or to the ".gather.tar.gpg"
             encrypted archive.
* filter: create a filtered snapshot from the specified snapshot in
             ".bss.d/" as "\<specified_subvol_name>_filter"
* revert: make snapshot "\<ISO_8601_date>.last" and replace the subvolume at
             the BASE directory (1st argument) with the specified snapshot
             "\<ISO_8601_date>.\<extension>" (2nd argument) found under
             "BSS_SNAP_DEST" specified in ".bss.conf".  This is intended only
             for the system snapshot mode. (This is experimental and untested
             feature with limited capabilities.  Use with extra care!)
* zap: zap (=delete) particular snapshot(s) specified by its arguments
             ("zap" is required to be typed in full text)
* template: make template files in the ".bss.d/" directory:
  *  ".bss.conf" (aging rule)
  *  ".bss.fltr[.disabled]" (filtering rule)
* batch FNB: change the current working directory to the user's home directory
             and source the shell script found at:
  *  "$XDG_CONFIG_HOME/bss/FNB" (non-root, $XDG_CONFIG_HOME set)
  *  "\~/.config/bss/FNB" (non-root, $XDG_CONFIG_HOME unset)
  *  "/etc/bss/FNB" (root)
* BASE: print the BASE directory and its filesystem type for "bss"
* jobs: list all systemd timer schedule jobs for bss


### ARGUMENTS

SUBCOMMANDs may be shortened to a single character.

For some SUBCOMMANDs, enxtra optional arguments after the explicit "PATH" may
be specified to provide arguments to them.

For "bss list", you may add the second argument to match snapshot "\<TYPE>".
"bss list . '(s.*|u.*)' " should list snapshots with "single", "snap" and
"usb" types.

For "bss copy PATH DEST_PATH", this is a combination of "bss snapshot" to
create a snapshot of the "$FS_BASE" directory for "PATH" and a wrapper for
"rsync" command with its first argument "$FS_PATH" and the second argument
"DEST_PATH".  This command copy specified data recursively within filesystem
boundaries.  Thus subvolumes and mounted filesystems are excluded.  This
command is also smart enough to skip the ".bss.d/" directory on both the
"$FS_BASE" directory and "DEST_PATH" to allow independent snapshot management
of data using "bss" on both ends.  The use of "--delete" option for "rsync"
is the intentional choice.  (The tailing "/" in "DEST_PATH" is removed.)

If "DEST_PATH" is a local path such as "/srv/backup", then

* sudo rsync -aHxS --delete --mkpath --filter="- .bss.d/"

is used to have enough privilege and to save the CPU load.  If this local
"DEST_PATH" doesn't exist, it is created in advance as:

 * a subvolume if it is on btrfs filesystem or,
 * a subdirectory if it is on non-btrfs filesystem.

If "DEST_PATH" is a local relative path without the leading  "/", then it is
treated as a relative path from the user's home directory.

If "DEST_PATH" is a remote path such as "[USER@]HOST:DEST_PATH", then

* rsync -aHxSz --delete --mkpath --filter="- .bss.d/"

is used to limit privilege and to save the network load. Also, this allows
"bss copy" to use the SSH-key stored by the user's home directory under
"\~/.ssh/".

For "bss gather PATH", files and directories are gathered recursively using 4
configuration files found in the PATH directory (or more precisely in the
"$FS_BASE" directory).

  * ".gather.dir.absrc" and ".gather.dir.relrc" gather files to the
    ".gather.dir" directory in the $FS_BASE directory.
  * ".gather.gpg.absrc" and ".gather.gpg.relrc" gather files to the
    ".gather.tar.gpg" encrypted archive in the $FS_BASE directory.
  * ".gather.dir.absrc" and ".gather.gpg.absrc" are for "/" directory
    as the source.
  * ".gather.dir.relrc" and ".gather.gpg.relrc" use the home
    directory as the source.

This "bss gather" is essentially a wrapper for

* rsync -aHS --delete-excluded --mkpath --filter="- .bss.d/" --filter=". .gather.*.*rc"

Unlike "bss copy", the recursive scope of "bss gather" is not limited within
filesystem volume nor subvolume.  The configuration files ".gather.*.*rc"
follow "FILTER RULES" in rsync(1) manpage.  If any of these are missing,
corresponding gather actions are skipped without error.  Even when error is
encountered, "bss gather" only emits logging messages and exits as success.
The use of "--delete-excluded" option for "rsync" is the intentional choice.

"bss zap" always operates on the current working directory as "PATH".  Thus
the first argument is not "PATH" but one of following action specifies:

* new: zap (=delete) the newest snapshot subvolume
* old: zap the oldest snapshot subvolume
* half: zap the older half of snapshot subvolumes
* \<subvolume>: zap specified snapshot subvolume (path with or without
                ".../.bss.d/" such as "2020-01-01T00:00:00+00:00.single").
                Multiple subvolumes may be specified.

Unless you have specific reasons to use "bss zap", you should consider to use
"bss process" to prune outdated snapshots.

For "bss revert PATH PATH_OLD", subvolume at PATH is replaced by the subvolume
at "PATH_OLD".  "PATH" can't be set to "/".

### NOTE

This "bss" command comes with examples for systemd scripts and apt hook script
to enable automatic "snapshot" operations.  This "bss" command also comes with
examples for systemd scripts to enable automatic daily "process" operation.

For some snapshots, different "TYPE" values may be used instead of its default
"single".  Notable ones are:

* TYPE="pre": automatic "snapshot" operation just before APT update
* TYPE="post"  automatic "snapshot" operation just after: APT update
* TYPE="copy": automatic "snapshot" operation just before "bss copy"
* TYPE="snap": automatic "snapshot" operation on timer event
* TYPE="usb": automatic "snapshot" operation on mount event (USB Storage)
* TYPE="last": automatic "snapshot" operation just before "bss revert"

This "bss" calculates time values related to age in the second and prints them
in the DAYS.HH:MM:SS format (HH=hour, MM=minute, SS=second).

You can make a snapshot just by "bss" alone.

You can use verbose "bss -v BASE" command to print current effective
configuration parameters without side effects.

This "bss" command can use systemd logger.  When used, the log of its
invocations can be viewed with:

* $ journalctl -a -b -t bss
* $ journalctl -f -t bss

Although "bss" is focused on the snapshot operation for btrfs, subcommands
which use "rsync" as their backend can be used for backup operations from any
filesystem.  This design allows us to create nice snapshot backups to a btrfs
partition on USB or remote storage from any filesystem to ensure data
redundancies. For "bss template PATH" on non-btrfs, ".bss.d/" directory and
related configuration files are created on "PATH" itself.  For "bss copy PATH
..." and "bss gather PATH" on non-btrfs, the "$FS_BASE" directory is searched
from "PATH" and is set when ".bss.d/" is found.

### CAVEAT

The source filesystem must be btrfs for many subcommands.

The non-root user who executes this command must be a member of "sudo".

"bss gather" may generate encrypted archive using GnuPG with the default key
normally set by "\~/.gnupg/gpg.conf".  This GnuPG configuration file location
may be changed by the value of environment variable "$GNUPGHOME". You need to
have access to the corresponding secret key to decrypt such archived data.
Please ensure that you can decrypt the archive in advance.  Failing to do so
may cause you to lose data.  See gpg(1).

Running filter script ".bss.fltr" drains CPU and SSD resources but it may save
SSD usage size significantly.  If you are not interested in reducing SSD usage
size by this script, rename from ".bss.fltr" to ".bss.fltr.disabled" and set
BSS_TMID_ACTION="no_filter" in ".bss.conf".

The "revert" operation is supported only for the system snapshot mode which
sets BSS_SNAP_DEST in ".bss.conf" to non-zero string.  APT updates can be
configured to create snapshots of the system using this system snapshot mode.
The "revert" operation can bring the system before the APT update operation.
This kind of "revert" operation must be performed from the secondary system on
another root filesystem and all subvolumes to be manipulated shouldn't be
accessed by other processes. You should manually mount using "/etc/fstab" for
all subvolumes under the subvolume to run "revert" operation and manage them
separately to keep the system recoverable since the snapshot operation isn't
recursive.

Copyright 2022 - 2024 Osamu Aoki \<osamu@debian.org>, GPL 2+
<!--
vim:set ai si sts=2 sw=2 et tw=79:

* 'README.md' is auto-generated file
* Edit usr/bin/bss, README.md? and run 'make README.md'
-->

## Note on gather configuration files

`bss gather` uses gather configuration files ".gather.*.*rc":

* ".gather.dir.absrc" and ".gather.gpg.absrc" to gather files with srcdir=`/` (root)
* ".gather.dir.relrc" and ".gather.gpg.relrc" to gather files with srcdir=`~/` (home)

For gather configuration file `.gather.rc`, `bss gather` executes `rsync` with
the following (excluding details):

```console
 $ rsync -a --filter=". .gather.rc" $srcdir $destdir
```

The syntax of gather configuration file is defined in the "FILTER RULES" in
rsync(1) manpage.

Although this gather configuration file can be written in any order, I usually
organize this file in the following order.

* Partial path exclusion match rules to be forced
  * file name match rule (e.g. "`- *~`" without "`/`")
  * dir name match rule (e.g., "`- .git/`" with only one "`/`" at the end)
* Full path inclusion match rules (pattern starts with "`/`")
  * the parent3 dir inclusion match rule (e.g., "`+ /a/`" with "`/`" at the end)
  * the parent2 dir inclusion match rule (e.g., "`+ /a/b/`" with "`/`" at the end)
  * the parent1 dir inclusion match rule (e.g., "`+ /a/b/c/`" with "`/`" at the end)
  * the target inclusion match rule (no "`/`" at the end)
    * inclusion match rule for individual target file (e.g., "`+ /a/b/c/targetfile`")
    * recursive inclusion match rule for files under target dir (e.g., "`+ /a/b/c/targetdir/***`")
* Full path fall-back all-exclusion match rule (e.g., "`- /***`")

The above execution is actually over-simplified.  In reality, details are taken
care to avoid gathering snapshot files under the `.bss.d/` directory as:

```console
 $ rsync -aHS --delete-excluded --mkpath --filter="- .bss.d/" \
              --filter=". .gather.rc" $srcdir $destdir
```

Please take a look at examples found in
`/usr/share/doc/bss/examples/home/osamu/rsync` and
`/usr/share/doc/bss/examples/home/osamu/Documents`.

## References

* [bss: tips](bss_tips.md)
* [Btrfs migration tips](https://wiki.debian.org/Btrfs%20migration)

