
# Tips

## Building local deb package of `bss`

Here is how to build `bss` deb package and installing it.

```
 $ git clone https://github.com/osamuaoki/bss.git
 $ cd bss
 $ debuild
 $ cd ..
 $ sudo dpkg -i bss_2.0.0_amd64.deb
```
## Migration of the root filesystem to `subvol=@rootfs` on Btrfs.

See [Btrfs migration](https://wiki.debian.org/Btrfs%20migration)

## Excluding files from the `snapshot` operation

If you wish to exclude files under a particular directory, simply creating a
pertinent subvolume containing those files in place of the directory allows to
exclude them to be a part of the `snapshot` operation.

## Database file and CoW issue

Please consider to set 'no copy on write' (C) attribute recursively on the
directory prior to placing files such as the database file in it.  For
example:

```
 $ sudo chattr -R +C /var/lib/mysql
```

I suppose that you need to stop database program before making snapshot/backup
of the filesystem containing it.

Maybe the same goes with the actively used disk image file.

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
