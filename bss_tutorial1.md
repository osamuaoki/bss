<!--
vim:set ai si sts=2 sw=2 et tw=79:
-->
# Tutorial for `bss` on ext4

## Example system

Let me present a simple system setup case of data snapshot and backup for the
Gnome desktop system (Debian Trixie 13) with UEFI PC hardware with the NVMe
SSD GPT disk as an example for tutorial.

Let's assume a few things.

* Official Debian installer was used as fresh install.
* A single ext4fs formatted partition `/dev/nvme0n1p5` was selected to be the root
  filesystem for `/` which also contains `/home`, `/usr`, `/var`, ....
* The UUID of this ext4fs is `fe3e1db5-6454-46d6-a14c-071208ebe4b1`.
* The hostname of this new system is `newhost`.
* The primary user (UID=1000, GID=1000) is `penguin`.
* The primary user is a member of the `sudo` group.

The shared partition for “EFI system partition” is also used by the installer
and is formatted as FAT32.  It is automatically mounted at `/boot/efi`.

## Intended configuration of `newhost` system

Backup all data under `/home/penguin` to a btrfs formatted USB storage device:

* when it is plugged-in and
* when GUI icon is clicked.

There will be time stamped read-only snapshots on the USB storage.

## Installation of `bss`

### For Debain/Ubuntu system (via APT)

Create `/etc/apt/sources.list.d/osamuaoki.sources` as:

```text
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

```console
 $ sudo apt update && sudo apt install bss
```

### For other system (or for testing)

```console
 $ git clone https://github.com/osamuaoki/bss.git
 $ cd bss
 $ sudo make bininstall
```

### For Debain/Ubuntu system (via local deb package)

```console
 $ git clone https://github.com/osamuaoki/bss.git
 $ cd bss
 $ debuild
 $ cd ..
 $ sudo dpkg -i bss_2.0.0_amd64.deb
```

## Configuring for `bss`

Run following commands to setup configuration files for `bss`:

```console
 $ bss template ~
```

This sets the base directory of the recursive backup with `rsync -rx` executed
by `bss`.

## Preparation of USB storage `BKUP_USB`

Prepare a USB storage media for backup by:

* partitioning your USB storage media
* (optionally) making its partition as LUKS encrypted) one
* formatting it with btrfs
* labeling this btrfs filesystem as `BKUP_USB`

Then this USB storage media can be auto-mounted by the Gnome desktop
environment to `/media/penguin/BKUP_USB` by `udisks2` package.

You can find out its systemd unit for mounting it.

```console
 $ systemctl list-units -t mount | fgrep -e '/media/penguin/BKUP_USB'
  media-penguin-BKUP_USB.mount    loaded active mounted /media/penguin/BKUP_USB
```

## Backup upon each mount event

Create `~/.config/systemd/user/bss-BKUP_USB.service` as:

```text
[Unit]
Description=USB Disk backup
Requires=media-penguin-BKUP_USB.mount
After=media-penguin-BKUP_USB.mount

[Service]
ExecStart=bss --type usb batch BKUP_USB

[Install]
WantedBy=media-penguin-BKUP_USB.mount
```

Create `~/.config/bss/BKUP_USB`

```text
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

```console
 $ systemctl --user enable bss-BKUP_USB.service
```

Somehow, I get the following unexpected spurious yellow warning.

```console
Unit /home/penguin/.config/systemd/user/bss-BKUP_USB.service is added as a dependency to a non-existent unit media-penguin-BKUP_USB.mount.
```

Despite this warning, USB storage seems to be getting backup data when my workstation is powered up with USB drive plugged-in or when it get plugged-in.

## GUI icon for manual backup

Since you may want to backup again after initial mount time backup, we offer
clickable GUI icon for its trigger.

Create `~/.local/share/applications/bss-BKUP_USB.desktop` as:

```text
[Desktop Entry]
Name=bss backup
Comment=USB Disk backup
ExecStart=bss --type usb batch BKUP_USB
Type=Application
```

## Tips

You can expand and customize above examples to your local needs.

Please see examples/ directory in the source code repository of this bss.

  https://github.com/osamuaoki/bss/tree/main/examples

There I use `secret-tool` to avoid including unnecessary information hard-coded
into source code and `notify-send` to help user with the situation awareness of
the slow background processes.

