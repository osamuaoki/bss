# Tips

## Excluding files from the `snapshot` operation

If you wish to exclude files under a particular directory, simply creating a
pertinent subvolume containing those files in place of the directory allows to
exclude them to be a part of the `snapshot` operation.

## Database file and CoW issue

NOTE: I may be wrong in this section. See more at
[BTRFS documentation: attribute](https://btrfs.readthedocs.io/en/latest/ch-file-attributes.html).

Please consider to set 'no copy on write' (C) attribute to the empty directory
prior to placing files such as the database file in it. For example:

```console
 $ sudo mv /var/lib/mysq /var/lib/mysq.orig
 $ sudo mkdir -p /var/lib/mysq
 $ sudo chattr +C /var/lib/mysql
 $ sudo cp -a /var/lib/mysq.orig/* /var/lib/mysq.orig/.* /var/lib/mysql
```

I suppose that you need to stop database program before making snapshot/backup
of the filesystem containing it.

Maybe the same goes with the actively used disk image file.

## rsync.net

To use rsync.net, we need to set up ssh keys.

 * https://www.rsync.net/resources/howto/ssh_keys.html

### rsync.net: Recovering files (basics)

For rsync.net service, following should help you recover the last data, use
`rsync` as:

```console
 $ mkdir -p ~/oldrsync
 $ cd ~/oldrsync
 $ rsync -a de1234@de1234.rsync.net:rsync .
 $ ls -laR
```

### rsync.net: Recovering files (older)

To recover the older backup data, use `rsync` as:

```console
 $ rsync -a de1234@de1234.rsync.net:.zfs/snapshot/daily_2022-01-01 .
```

For list of available older backups

```console
 $ ssh de1234@de1234.rsync.net ls -lsa .zfs/snapshot
```
