<!--
vim:set ai si sts=2 sw=2 et tw=79:
-->
# Tutorial for `bss`

Let me present a simple system setup case of data snapshot and backup for the
Gnome desktop system (Debian Bookworm 12) with UEFI PC hardware with the NVMe
SSD GPT disk as an example for tutorial.

Let's assume a few things.

* Official Debian installer was used as fresh install.
* The btrfs formatted partition `/dev/nvme0n1p5` was selected to be the root
  filesystem.
* The installer automatically made subvolume `@rootfs` within this btrfs.
* The UUID of this btrfs is fe3e1db5-6454-46d6-a14c-071208ebe4b1`.
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
and many USB storage devices.)

I tend to forget to run snapshot and backup scripts.  So I want these backup
and snapshot actions to be as automatic and easy as possible by using systemd
features and Gnome featurs.

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
 Version: GnuPG v1.4.10 (GNU/Linux)
 . 
 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
 xqPj8/NMvWK8mJoL07R52TxDk6k=
 =2eP9
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

## Snapshot upon each apt event

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

## GUI icon for remote backup

Create `~/.local/share/applications/bss-rsync.desktop` as:

```
[Desktop Entry]
Categories=Office;
Comment=Simple environment checker
Exec=bss batch rsyncnet
Name=Backup to Rsync.net
Type=Application
```


## Getting started

### Console basics

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


See examples files for how to set and use systemd unit and desktop file by
placing them under your home directory accordingly.  Also, there is an example
hook script for apt.  (Files needs to be adjusted for your local subvolume
paths.)  The following may be handy to see how this working.

```
 $ journalctl -a -b -t bss
```

You need to run following commands to enable systemd service files.

```
 $ cd ~/.config/systemd/user/
 $ systemctl --user enable bss-snap.timer
 $ systemctl --user enable bss-BKUP_USB.service
```

Here:

* `bss-snap.timer` is for the timer induced execution of `bss` commands.
* `bss-BKUP_USB.service` is for the mount event induced execution of `bss` commands.
* Batch files in `~/.config/bss/` are used to define actual execution of `bss` commands.

File paths are:

 * `/path/to/subvol/.bss.d/20???????`  --- read-only (RO) snapshots
 * `/path/to/subvol/.bss.d/.bss.conf`  --- configuration file
 * `/path/to/subvol/.bss.d/.bss.fltr`  --- filter script

### Customization of aging behavior

* Create template configuration and filter by `bss t`
  * Adjust configuration by editing `.bss.d/.bss.conf`
  * Adjust filter by editing `.bss.d/.bss.conf`

## Consideration and strategy to secure data

In order to be absolutely sure to recover from accidental erase of important
data, disastrous disk failure, or even loss of the workstation, it's nice to
have followings readily available:

* RO snapshots on the local disk
* RO backup snapshots on the plug-in USB disk
* RO backup snapshots on the [rsync.net](https://rsync.net) host

I tend to forget to run snapshot and backup scripts.  So I want these to be as
automatic and easy as possible.  Considering my usage, I plan to set up as follows:

* Private data (`~/`) needs the best protection:
  * make *automatic* btrfs local on-disk snapshots with 15 minute interval timer
  * make *automatic* rsync backup to local USB storage media upon each mount event
  * make *easy* rsync backup to remote backup server upon single click of a GUI icon
* System data (`/`) 
  * make *automatic* btrfs local on-disk snapshots of system data upon each apt operation

The backup and snapshot action is realized by the `bss` command which is
essentially a shell wrapper of `btrfs` and `rsync` commands.

Remote backup site such as [rsync.net](https://rsync.net) on which one doesn't
have full control has the inherent security concern.  Date send to the such
service must be encrypted.

The *automatic* functionality is accommodated by the systemd functionality.

The easy program is realized by the GUI icon by creating its desktop file.

Let me describe key points to secure data on the desktop workstation.

## Snapshot with 15 minute interval timer

This is realized by using systemd timer unit.

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
seconds after the start of the system and 300 seconds after its last execution.

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

Here, the use of `"$BSS_MAY"` allows `bss batch --may ...` to force execution
of all lines without stopping in the middle even when they return error.

Prepare each subvolumes as:

```
 $ bss template ~
 $ bss template ~/Documents
 $ mount 
 $ sudo bss template /btrfs_root/@rootfs
```

Then, activate this timer unit as:
```sh
 $ systemcrl --user enable bss-snap.timer
```

## Example USB storage setup

Prepare a USB storage media for backup by:
* partitioning your USB storage media
* (optionally) making its partition as LUKS encrypted) one
* formatting it with btrfs
* labeling this btrfs filesystem as `BKUP_USB`

Then this USB storage media can be auto-mounted by the Gnome desktop
environment to `/media/penguin/BKUP_USB` by `udisks2` package.

Let's find out its systemd unit for mounting it.

```
 $ systemctl list-units -t mount | fgrep -e '/media/penguin/BKUP_USB'
  media-penguin-BKUP_USB.mount    loaded active mounted /media/penguin/BKUP_USB
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

## Snapshot upon each apt event

Create `/etc/apt/apt.conf.d/80bss` as:

```
  DPkg::Pre-Invoke  { "/usr/bin/bss snapshot --logger --type=pre  / || true" ; } ;
  DPkg::Post-Invoke { "/usr/bin/bss snapshot --logger --type=post / || true" ; } ;
```

Then `bss snapshot ...` for root filesystem is invoked for every APT event.

Here, `/bss.d/.bss.conf` needs to be modified to enable system snapshot mode as:

```
BSS_SNAP_DEST="/btrfs_root/@rootfs-snapshots"
```

## GUI icon for remote backup

Create `~/.local/share/applications/bss-rsync.desktop` as:

```
[Desktop Entry]
Categories=Office;
Comment=Simple environment checker
Exec=bss batch rsyncnet
Name=Backup to Rsync.net
Type=Application
```

Create `~/.config/bss/rsyncnet` as:

```
########################################################################
# Backup to the rsync.net
########################################################################
# SSH access to rsync.net with SSH key needs to be enabled
# Source directory of secret data to create LUKS encrypted image
SECRET_DIR="secret"
# Store rsync.net account name with:
#   $ secret-tool store --label 'Rsync.net account name' rsync.net account
#   Password:<type full account name e.g.: ab1234@ab1234.rsync.net>
# Verify rsync.net account name with:
#   $ secret-tool lookup rsync.net account
#   ab1234@ab1234.rsync.net
RSYNC_ACCOUNT="$(secret-tool lookup rsync.net account)"
# Source directory to copy to rsync.net
RSYNC_DIR="rsync"

# Creates encrypted archive in "$RSYNC_DIR" with .gather.gpg
bss gather "$RSYNC_DIR"
bss copy "$RSYNC_DIR" "$RSYNC_ACCOUNT:$RSYNC_DIR"
__logger ssh "$RSYNC_ACCOUNT" ls -lA "$RSYNC_DIR"
```

