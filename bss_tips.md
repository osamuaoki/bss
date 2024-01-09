# Tips

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

## bss: system files

In order to make roll back of the whole system file easier, `bss` now supports
system mode.

Files under "examples/etc/apt/apt.conf.d/80bss" is meant to be installed to
"/etc/apt/apt.conf.d/80bss" for making snapshots of system data for every APT
operations.

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

### rsync.net: Recovering files (older)

To recover the older backup data, use `rsync` as:

```
 $ rsync -a de1234@de1234.rsync.net:.zfs/snapshot/daily_2022-01-01 .
```

For list of available older backups
```
 $ ssh de1234@de1234.rsync.net ls -lsa .zfs/snapshot
```
