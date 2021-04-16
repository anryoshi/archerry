#!/bin/bash -e

# Script for migrating Arch from upstream kernel
# back to the Raspberry Pi supported kernel
# src: https://github.com/raspberrypi/linux
# bin: https://github.com/raspberrypi/firmware

# Initializing the pacman keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Updating package database and upgrading system
pacman -Sy --noconfirm
pacman -Su --noconfirm

# Migrating to RPI kernel
pacman -S --noconfirm linux-raspberrypi4

# We need to update fstab accordingly before the reboot
sed -i 's/mmcblk1/mmcblk0/g' root/etc/fstab

reboot
