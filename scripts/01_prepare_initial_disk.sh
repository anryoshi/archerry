#!/usr/bin/env bash

set -e
set -x

# Script for creating standard partitioning of disk for Raspberry Pi
# Dependencies:
#   - sfdisk
#   - wipefs
#   - wget
#   - md5sum
#   - blockdev
#   - bc

show_help() {
    printf 'Usage: 01_prepare_initial_disk.sh -d <device> [-t <temp_dir>]\n' >&2
    exit 1
}

device=
temp_dir="." # Used for storing downloaded files

while :; do
  case $1 in
    -h)
      show_help
      exit
      ;;
    -d)
      if [ -n "$2" ]; then
        device=$2
        shift
      else
        printf 'ERROR: device requires a non-empty option argument.\n' >&2
        exit 1
      fi
      ;;
    -t)
      if [ -n "$2" ]; then
        temp_dir=$2
        shift
      else
        printf 'ERROR: temp_dir requires a non-empty option argument.\n' >&2
        exit 1
      fi
      ;;
    *)
      if [ -z "$1" ]; then
          break
      fi
      printf 'ERROR: Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

if [ -z "$device" ]; then
  printf 'ERROR: device requires a non-empty option argument.\n' >&2
  show_help
  exit 1
fi

if [ -z "$device" ]; then
  printf 'ERROR: device requires a non-empty option argument.\n' >&2
  show_help
  exit 1
fi

if [ ! -b "$device" ]; then
  printf 'ERROR: device not found.\n' >&2
  show_help
  exit 1
fi

cd "$temp_dir"
# Downloading a latest Arch ARM
root_fs_archive="ArchLinuxARM-rpi-aarch64-latest.tar.gz"
root_fs_archive_md5="ArchLinuxARM-rpi-aarch64-latest.tar.gz.md5"
root_fs_archive_url="http://os.archlinuxarm.org/os/$root_fs_archive"
root_fs_archive_url_md5="http://os.archlinuxarm.org/os/$root_fs_archive_md5"

printf "Downloading $root_fs_archive from os.archlinuxarm.org...\n"
if [ ! -f "$root_fs_archive_md5" ]; then
  wget -q "$root_fs_archive_url_md5"
fi
if [ ! -f "$root_fs_archive" ]; then
  wget -q --show-progress "$root_fs_archive_url"
else
  printf "Already downloaded...\n"
fi

printf "Verifying MD5 of $root_fs_archive...\n"
if ! md5sum --status -c "$root_fs_archive.md5"; then
  printf 'ERROR: MD5 checksum verification failed.\n' >&2
  exit 1
fi


read -p "You are going rewrite $device. Are you sure (y/n)? " choice
case "$choice" in
  y|Y ) printf "Starting partitioning...\n";;
  n|N ) exit 1;;
  * ) exit 1;;
esac

sudo sfdisk -d /dev/sdb 2>&1 | grep -q 'does not contain a recognized partition table'

if [ "$?" -eq 1 ]; then
  printf "Deleting previous partitioning tables...\n"
  sfdisk -q --delete "$device"
  
  printf "Wiping magic bytes...\n"
  wipefs -q -a "$device"
fi

printf "Counting sectors...\n"
device_sectors=$(blockdev -q --getsz "$device")
root_sectors_num=$(echo "$device_sectors - 411648" | bc)
printf "Root size in sectors will be: $root_sectors_num\n"

boot_part="${device}1"
root_part="${device}2"

printf "Creating new partition...\n"
sfdisk -q "$device" <<NEWPARTITION
label: dos
$boot_part : start=2048, size=409600, type=c
$root_part : start=411648, size=$root_sectors_num, type=83
NEWPARTITION
printf "Partitioning done!\n"

boot_mount="boot"
root_mount="root"

printf "Formating boot partitioning as vfat...\n"
mkfs.vfat "$boot_part"

printf "Mounting boot partitioning...\n"
mkdir -p "$boot_mount"
mount "$boot_part" "$boot_mount"

printf "Formating root partitioning as ext4...\n"
mkfs.ext4 "$root_part"

printf "Mounting boot partitioning...\n"
mkdir -p "$root_mount"
mount "$root_part" "$root_mount"

printf "Unpacking rootfs...\n"
tar -zxf "$root_fs_archive" -C "$root_mount"
sync

printf "Copying to boot...\n"
mv "$root_mount/boot"/* "$boot_mount"

printf "Modyfing fstab...\n"
sed -i 's/mmcblk0/mmcblk1/g' "$root_mount/etc/fstab"

printf "Unmounting boot and root...\n"
umount "$boot_mount" "$root_mount"

