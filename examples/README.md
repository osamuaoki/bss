# Examples

This examples/ directory contains a set of configuration examples and scripts
on my note PC.

All these require us to set up ssh keys.

 *  https://www.rsync.net/resources/howto/ssh_keys.html

## Typical use case (data files)

Files under ".config/systemd/" are meant to be installed to
"~/.config/systemd/" for making scheduled snapshots of user data for the
following situation.

Let's consider data files and configuration in the home directory.  Migrating
them to btrfs is trivial and allow us to make casual snapshots.  We can easily
accumulate too many snapshots.  Pruning old snapshots is tedious task.  Also
snapshots only help easy roll back of overwritten and erased data but don't
protect us from disk failure.  For recovering from disk failure, we need to
make remote backups. Remote backup has inherent security concern and encryption
of data needs to be deployed.

`bss` command used with `secret-folder` can address this situation.

Let's consider to have following path in independent btrfs subvolumes:

 * ~/                 snapshots and selective secure network backups
 * ~/github/          snapshots (no need for backup)
 * ~/salsa/           snapshots (no need for backup)
 * ~/rsync/           snapshots and network backups
 * ~/Documents/       snapshots and secure network backups
 * ~/Photo/           snapshots and USB backups

`bss snapshot` can make snapshots in the `.bss.d/` .

`bss copy` can make network backups and USB backups.  The destination s set by
the "BSS_COPY_DEST" value in the`.bss.d/.bss.conf` file.

For secure backups, use `secret-folder` command to create and update encrypted
disk image file (LUKS+ext4).  The default disk image file path of
`secret-folder` command is `~/rsync/secret.img` .  This path can be changed by
exporting `$RSYNC_TARGET` and `$DEVMAPPER_TARGET` .  The selection of files to
be copied into `~/rsync/secret.img` are listed in `~/.secretrc` .

When updating `~/rsync/secret.img`, its content is mounted to `~/secret/` .
(normally it is not kept as mounted unless you start `secret-folder` followed
by `keep`.

For network backups, you need to have access to a remote server accepting ssh
and `rsync` connection.  I currently use rsync.net service. (For other cloud
services, this code need updated to support `rclone` command.  This is TODO and
patch welcomed.)

Since `~/github/` and `~/salsa/` contain publicly mirrored contents, I don't
bother to make their remote/USB copies.

## Recovering files (basics)

For rsync.net service, following should help you recover the last data, use
`rsync` as:

```
 $ mkdir -p ~/oldrsync
 $ cd ~/oldrsync
 $ rsync -a de1234@de1234.rsync.net:rsync .
 $ ls -laR
```

## Recovering files (encrypted)

The above basic method to recover files leaves encrypted disk image
`secret.img` in `~/oldrsync`.

You can also download specifically for the disk image secret.img with

```
 $ rsync -a de1234@de1234.rsync.net:rsync/secret.img .
```

You can inspect contents in the downloaded `secret.img` as:

```
 $ secret-folder                        # make sure to unmount
 $ cd ~/rsync
 $ mv secret.img secret-keep.img        # if secret.img exists
 $ mv ~/oldrsync/secret.img secret.img
 $ secret-folder mount keep
 $ cd ~/secret; ls -laR
```

(Here, secret.img must be placed in the original location with the original
name to use the passphrase stored in GNOME `secret-tool`.)

Alternatively, you can inspect contents in downloaded `secret.img` as:

```
 $ mkdir -p ~/oldrsync
 $ mkdir -p ~/oldrsecret
 $ export RSYNC_TARGET=oldrsync
 $ export DEVMAPPER_TARGET=oldrsecret
 $ cd ~/oldrsync
 $ rsync -a de1234@de1234.rsync.net:rsync/secret.img .
 $ mv secret.img oldsecret.img
 $ secret-folder mount keep ask
  ... (enter passphrase)
 $ cd ~/oldsecret; ls -laR
```

## Recovering files (older)

To recover the older backup data, use `rsync` as:

```
 $ rsync -a de1234@de1234.rsync.net:.zfs/snapshot/daily_2022-01-01 .
```

For list of available older backups
```
 $ ssh de1234@de1234.rsync.net ls -lsa .zfs/snapshot
```

## Other use case (system files)

Files under `etc/` are meant to be installed to `/etc/` for making snapshot of
the root filesystem upon APT operation.  Since recent Debian testing is very
stable, I stop using the APT snapshot capabilities.  So these under `etc/` are
FYI examples without recent usage.

I simply have dual bootable Linux system to minimize damages of broken system
files.  (There are some supports to roll back system files in `bss`, but
setting up btrfs for / is non-trivial.)

