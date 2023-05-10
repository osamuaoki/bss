# Examples

This examples/ directory contains a set of configuration examples and scripts
on my note PC.

Let's consider data files and configuration in the home directory.  Migrating
them to btrfs is trivial and allows us to make casual snapshots.  We can easily
accumulate too many snapshots.  Pruning old snapshots is tedious task.  Also
snapshots only help easy roll back of overwritten and erased data but don't
protect us from disk failure.  For recovering from disk failure, we need to
make remote backups. Remote backup has inherent security concern and encryption
of data needs to be deployed.

`bss` command used with `luksimg` can address this situation.

## bss: user data (typical case)

Files under ".config/systemd/" are meant to be installed to
"~/.config/systemd/" for making scheduled snapshots of user data for the
following situation.

Let's consider to have following path in independent btrfs subvolumes:

 * ~/                 snapshots and selective secure network backups
 * ~/github/          snapshots (no need for backup)
 * ~/salsa/           snapshots (no need for backup)
 * ~/rsync/           snapshots and network backups
 * ~/Documents/       snapshots and secure network backups
 * ~/Photo/           snapshots and USB backups

`bss snapshot` can make snapshots in the `.bss.d/` .

`bss copy` can make network backups and USB backups.  The destination is set by
the "BSS_COPY_DEST" value in the`.bss.d/.bss.conf` file.

## bss: system files

In order to make roll back of the whole system file easier, `bss` now supports
system mode.

Files under "examples/etc/apt/apt.conf.d/80bss" is meant to be installed to
"/etc/apt/apt.conf.d/80bss" for making snapshots of system data for every APT
operations.

## luksimg

For secure backups, use `luksimg` command to create and update encrypted disk
image file (LUKS+ext4).  The default disk image file path of `luksimg` command
is `~/rsync/secret.img` .  It is mounted on `~/secret.mnt/`. The selection of
files and directories to be copied into `~/rsync/secret.img` are listed in
`~/secret.mnt/.gatherrc` .

Please note `luksimg` uses the passphrase stored in GNOME `secret-tool` with
`attribute` to be `LUKS` and  `value` to be the full expanded path
corresponding to `~/rsync/secret.img`.  (Use GNOME seahose for GUI management.)

## Backup script examples

For USB storage device backup, `examples/bin/bu` provides an example to use `bss`.

For network backups, `examples/bin/rbu` provides an example to use `bss` and `luksimg`.

Both of these are not auto start.

Since `~/github/` and `~/salsa/` contain publicly mirrored contents, I don't
bother to make their remote copies.

For USB copies, I limit data for regular backup to SSD.  I use HDD for large static data backup.

## rsync.net

To use rsync.net, we need to set up ssh keys.

 *  https://www.rsync.net/resources/howto/ssh_keys.html

### rsync.net: Recovering files (basics)

For rsync.net service, following should help you recover the last data, use
`rsync` as:

```
 $ mkdir -p ~/oldrsync
 $ cd ~/oldrsync
 $ rsync -a de1234@de1234.rsync.net:rsync .
 $ ls -laR
```

### rsync.net: Recovering files (encrypted)

The above basic method to recover files leaves encrypted disk image
`secret.img` in `~/oldrsync`.

You can also download specifically for the disk image secret.img with

```
 $ rsync -a de1234@de1234.rsync.net:rsync/secret.img .
```

You can inspect contents in the downloaded `secret.img` as:

```
 $ luksimg umount                       # make sure to unmount
 $ cd ~/rsync
 $ mv secret.img secret-keep.img        # if secret.img exists
 $ mv ~/oldrsync/secret.img secret.img
 $ luksimg mount
 $ cd ~/secret.mnt; ls -laR
```

(Here, secret.img must be placed in the original location with the original
name to use the passphrase stored in GNOME `secret-tool` and you may be able to
check it using GNOME seahorse.)

Alternatively, you can inspect contents in downloaded `secret.img` as:
XXX FIXME XXX
```
 $ mkdir -p ~/oldrsync
 $ mkdir -p ~/oldrsecret
 $ export DISK_IMG_DIR=oldrsync
 $ export DISK_IMG_FILE=oldrsecret
 $ cd ~/oldrsync
 $ rsync -a de1234@de1234.rsync.net:rsync/secret.img .
 $ mv secret.img oldsecret.img
 $ luksimg -p mount
  ... (enter passphrase)
 $ cd ~/oldsecret; ls -laR
```

### rsync.net: Recovering files (older)

To recover the older backup data, use `rsync` as:

```
 $ rsync -a de1234@de1234.rsync.net:.zfs/snapshot/daily_2022-01-01 .
```

For list of available older backups
```
 $ ssh de1234@de1234.rsync.net ls -lsa .zfs/snapshot
```
## Set up passwordless ssh access

XXX FIXME XXX
