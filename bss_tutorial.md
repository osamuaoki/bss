<!--
vim:set ai si sts=2 sw=2 et tw=79:
-->
# Tutorial for `bss`

## Example system

Let me present a simple system setup case of data snapshot and backup for the
Gnome desktop system (Debian Bookworm 12) with UEFI PC hardware with the NVMe
SSD GPT disk as an example for tutorial.

Let's assume a few things.

* Official Debian installer was used as fresh install.
* The btrfs formatted partition `/dev/nvme0n1p5` was selected to be the root
  filesystem.
* The installer automatically made subvolume `@rootfs` within this btrfs.
* The UUID of this btrfs is `fe3e1db5-6454-46d6-a14c-071208ebe4b1`.
* The hostname of this new system is `newhost`.
* The primary user (UID=1000, GID=1000) is `penguin`.
* The primary user is a member of the `sudo` group.

The shared partition for “EFI system partition” is also used by the installer
and is formatted as FAT32.  It is automatically mounted at `/boot/efi`.

## Intended configuration of `newhost` system

Let's consider to setup a simple system using 2 subvolumes:

* System data subvolume `@rootfs` mounted on `/`
* User data subvolume `@penguin` mounted on `~/`.

(Actual system setup which I use is more complicated to handle many subvolumes
and many USB storage devices.  See 
[examples directory in this source](https://github.com/osamuaoki/bss/tree/main/examples) )

I tend to forget to run snapshot and backup scripts.  So I want these backup
and snapshot actions to be as automatic and easy as possible by using systemd
features and Gnome features.

Let's consider to setup followings:

* For system data:
  * make *automatic* btrfs local on-disk snapshots of system data upon each apt operation
* For user data:
  * make *automatic* btrfs local on-disk snapshots with 15 minute interval timer
  * age and process *automatic* older snapshots after 60 minutes of the system start
  * make *automatic* rsync backup to local USB storage media upon each mount event
  * make *easy* rsync backup to remote backup server upon single click of a GUI icon

## Reconfiguration of `newhost` system

As installed, `~/` (== `/home/penguin/`) is a directory in the subvolume
`@rootfs`.  Let's make this as subvolume `@penguin` at the root of this root
filesystem.

The first step of reconfiguration is to reboot this PC using the [system-rescue
USB stick](https://www.system-rescue.org/) into rescue system environment and
mount `newhost` system on `/target` and make system reconfiguration as:

```
 rescue # mkdir /target
 rescue # mount UUID=fe3e1db5-6454-46d6-a14c-071208ebe4b1 /target
 rescue # btrfs subvolume create /target/@penguin
 rescue # rsync -ax /target/@rootfs/home/penguin/ /target/@penguin
 rescue # chown 1000:1000 /target/@penguin
 ```

The 2nd step of reconfiguration is to move out old data and create a new empty
directoy to be used as the mount point.

 ```
 rescue # mv /target/@rootfs/home/penguin /target/@rootfs/home/penguin-old
 rescue # mkdir -p /target/@rootfs/btrfs_root
 rescue # mkdir -p /target/@rootfs/home/penguin
 rescue # chown 1000:1000 /target/@rootfs/home/penguin
```

The 3rd step of reconfiguration is to update `/target/@rootfs/etc/fstab` under
this rescue environment as:

```
UUID=fe3e1db5-6454-46d6-a14c-071208ebe4b1 /             btrfs defaults,subvol=@rootfs 0 0
UUID=fe3e1db5-6454-46d6-a14c-071208ebe4b1 /btrfs_root   btrfs defaults,subvol=/ 0 0
UUID=fe3e1db5-6454-46d6-a14c-071208ebe4b1 /home/penguin btrfs defaults,subvol=@penguin 0 1
```

Now this PC is ready to be rebooted back into the normal `newhost` instance.


## Installation of `bss`

### For Debain/Ubuntu system (via APT)

Create `/etc/apt/sources.list.d/osamuaoki.sources` as:

```
Types: deb
URIs: https://osamuaoki.github.io/debian/
Suites: sid
Components: main
Signed-By:
 -----BEGIN PGP PUBLIC KEY BLOCK-----
 .
 mDMEZZpSFhYJKwYBBAHaRw8BAQdA9T6mXRx7Zc64kQC+dKB2RgxNHK0+KFlCT8b/
 JtFAWRu0HU9zYW11IEFva2kgPG9zYW11QGRlYmlhbi5vcmc+iJIEExYIADsCGwMF
 CwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQTYnmsJtCCYzq8IGrFtbTgJIV9yDQUC
 ZZpXMAIZAQAKCRBtbTgJIV9yDc+YAQDhuq/q76qobfHKi8C2MT83u1qZkg2eCpEF
 UkyvrE59fwD4+d+IbCls19F3MCRuEmyvYQr+sghC82lnUiFOxUq/DbQhT3NhbXUg
 QW9raSA8b3NhbXUuYW9raUBnbWFpbC5jb20+iJAEExYIADgWIQTYnmsJtCCYzq8I
 GrFtbTgJIV9yDQUCZZpVVQIbAwULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRBt
 bTgJIV9yDehWAP9lG8DUBwUPl0kCTezQItOxQfDXgJ0Lyhv8dv4B1iWxjgEA8YBv
 gCgDGby+pQmRX/STM7fu5LG62785oIj17HuMaQG4OARlmlIWEgorBgEEAZdVAQUB
 AQdA+q2tgbmHC7MQv5bTHyawYrITRw7Gdg7M0p0+oSRtzS8DAQgHiHgEGBYIACAC
 GwwWIQTYnmsJtCCYzq8IGrFtbTgJIV9yDQUCZZpU3QAKCRBtbTgJIV9yDdz6AQC8
 yC8mQnwkj9D2x84oSdEpAckJ/e47kLDN3y/HIOwXbAD/ZCv2Ek1Exh/7SrxNL65J
 ipPuCsH1vTsxbEE14mEs2Ag=
 =IDSM
 -----END PGP PUBLIC KEY BLOCK-----
# This is written in DEB822-STYLE FORMAT as described in sources.list (5)
```

This adds my personal APT repository.  Then `bss` can be installed by
`sudo aptitude -u` or by:

```
 $ sudo apt update && sudo apt install bss
```

### For other system (or for testing)

```
 $ git clone https://github.com/osamuaoki/bss.git
 $ cd bss
 $ sudo make bininstall
```

### For Debain/Ubuntu system (via local deb package)

```
 $ git clone https://github.com/osamuaoki/bss.git
 $ cd bss
 $ debuild
 $ cd ..
 $ sudo dpkg -i bss_2.0.0_amd64.deb
```

## Configuring subvolumes for `bss`

Run following commands to setup configuration files for `bss`:

```
 $ sudo bss template /
 $ sudo mkdir -p /btrfs_root/root_snapshots
 $ bss template ~
```

Update `/bss.d/.bss.conf` with `BSS_SNAP_DEST="/btrfs_root/root_snapshots"`.

If you don't want to run filter at TMID for `/`, you can optionally update
`/bss.d/.bss.conf` with `BSS_TMID_ACTION="no_filter"` and remove
`/bss.d/.bss.fltr` file.

## Preparation of USB storage `BKUP_USB`

Prepare a USB storage media for backup by:

* partitioning your USB storage media
* (optionally) making its partition as LUKS encrypted) one
* formatting it with btrfs
* labeling this btrfs filesystem as `BKUP_USB`

Then this USB storage media can be auto-mounted by the Gnome desktop
environment to `/media/penguin/BKUP_USB` by `udisks2` package.

You can find out its systemd unit for mounting it.

```
 $ systemctl list-units -t mount | fgrep -e '/media/penguin/BKUP_USB'
  media-penguin-BKUP_USB.mount    loaded active mounted /media/penguin/BKUP_USB
```

## Snapshot with 15 minute interval timer

Create `~/.config/systemd/user/bss-snap.timer` as:
```
# activate by: systemctl --user enable bss-snap.timer
[Unit]
Description=Run bss commands hourly
Documentation=man:bss(1)

[Timer]
OnStartupSec=30
OnUnitInactiveSec=900

[Install]
WantedBy=timers.target
```
This is a time unit for `bss-snap.service`.  `bss-snap.service` is started 30
seconds after start of the system and 300 seconds after its last execution.

Create `~/.config/systemd/user/bss-snap.service` as:
```
[Unit]
Description=Run bss commands to make snapshots
Documentation=man:bss(1)
# journalctl -a -b -t bss

[Service]
Type=oneshot
Nice=15
ExecStart=bss --type snap batch snapshots
IOSchedulingClass=idle
CPUSchedulingPolicy=idle
StandardInput=null
# No logging (use systemd logging)
StandardOutput=null
StandardError=null
#StandardOutput=append:%h/.cache/systemd-bss.log
#StandardError=append:%h/.cache/systemd-bss.log
```

Create `~/.config/bss/snapshots`
```
# make new snapshots
bss snapshot           || "$BSS_MAY"
bss gather   Documents || "$BSS_MAY"
bss snapshot Documents || "$BSS_MAY"
# clean up old snapshots
bss process            || "$BSS_MAY"
bss process  Documents || "$BSS_MAY"
```

Here, use of `"$BSS_MAY"` allows `bss batch --may ...` to force execution of
all lines without stopping in the middle.

Prepare subvolumes as:

```
 $ bss template ~
 $ bss template ~/Documents
 $ sudo bss template /
```

Update `/bss.d/.bss.conf` if you want to optimize aging behavior to your needs.

Then, activate this timer unit as:
```sh
 $ systemcrl --user enable bss-snap.timer
```

## Backup upon each mount event 

Create `~/.config/systemd/user/bss-BKUP_USB.service` as:
```
[Unit]
Description=USB Disk backup
Requires=media-penguin-BKUP_USB.mount
After=media-penguin-BKUP_USB.mount

[Service]
ExecStart=bss --may --type usb batch BKUP_USB

[Install]
WantedBy=media-penguin-BKUP_USB.mount
```

Create `~/.config/bss/BKUP_USB`
```
########################################################################
# make new backup copy (path are relative from $HOME)
# * source is a btrfs subvolume at ~/SRC_SUBVOL
#   * always ignore error from gather
# * destination is auto-mountable partition on a USB drive:
#   * formatted as btrfs and
#   * labeled as 'DST_LABEL'
########################################################################
bss_usb_backup () {
  # $1: SRC_SUBVOL
  # $2: DST_LABEL
  bss gather "$1" || true
  bss copy   "$1" "/media/$(id -un)/$2/$1" || $BSS_MAY
  bss snap        "/media/$(id -un)/$2/$1" || $BSS_MAY
  bss process     "/media/$(id -un)/$2/$1" || $BSS_MAY
}

# Backup to BKUP_USB (high frequency backup SSD device)
bss_usb_backup Documents BKUP_USB

# vim:se sw=2 ts=2 sts=2 et ai tw=78:
```

Then, activate this service unit as:

```sh
 $ systemctl --user enable bss-BKUP_USB.service
```

Somehow, I get the following unexpected spurious yellow warning.

```
Unit /home/penguin/.config/systemd/user/bss-BKUP_USB.service is added as a dependency to a non-existent unit media-penguin-BKUP_USB.mount.
```

Despite this warning, USB storage seems to be getting backup data when my workstation is powered up with USB drive plugged-in or when it get plugged-in.

## Snapshot upon each APT event

For the filesystem containing the system data, such as `@rootfs`, it is easier
to perform recovery operation if its snapshots reside in an absolute path
outside of the original filesystem.  `BSS_SNAP_DEST` variable in
`.bss.d/.bss.conf` can be used to enable system snapshot mode.

Here is an example to make snapshot of system image for `@rootfs`.

Create `/etc/apt/apt.conf.d/80bss` as:

```
  DPkg::Pre-Invoke  { "/usr/bin/bss snapshot --logger --type=pre  / || true" ; } ;
  DPkg::Post-Invoke { "/usr/bin/bss snapshot --logger --type=post / || true" ; } ;
```

Then `bss snapshot ...` for root filesystem is invoked for every APT event.

Here, `/bss.d/.bss.conf` has:

```
BSS_SNAP_DEST="/btrfs_root/@rootfs-snapshots"
```

If something goes wrong with the system with APT or anything, make a snapshot
of `/` and reboot with rescue media into rescue environment.

* remove `@rootfs` subvolume
* make a read-write copy subvolume `@rootfs` from one of the older but good snapshot in `/btrfs/main/@rootfs-snapshots`

## GUI icon for remote backup

Since remote network backup needs fast and cheap network connection, it is best
realized by offering clickable GUI icon for its trigger.

Create `~/.local/share/applications/bss-rsync.desktop` as:

```
[Desktop Entry]
Name=bss remote backup
Comment=rsync from ~/rsync to rsync.net
Exec=bss batch rsyncnet
Type=Application
```

Create `~/.config/bss/rsyncnet` as:

```
########################################################################
# Backup to the rsync.net
########################################################################
# You need to set your account here.  (This is fake one):
RSYNC_ACCOUNT="ab1234@ab1234.rsync.net"
# Source directory to copy to rsync.net:
RSYNC_DIR="rsync"

# SSH access to rsync.net with SSH key needs to be enabled

# Creates encrypted archive in "$RSYNC_DIR" with .gather.gpg.relrc and
# .gather.gpg.absrc
bss gather "$RSYNC_DIR" || true

bss copy "$RSYNC_DIR" "$RSYNC_ACCOUNT:$RSYNC_DIR" || $BSS_MAY
__logger ssh "$RSYNC_ACCOUNT" ls -lA "$RSYNC_DIR" || $BSS_MAY
```

## Tips

You can expand and customize above examples to your local needs.

Please see examples/ directory in the source code repository of this bss.

  https://github.com/osamuaoki/bss/tree/main/examples

There I use `secret-tool` to avoid including unnecessary information hard-coded
into source code and `notify-send` to help user with the situation awareness of
the slow background processes.

