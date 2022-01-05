#!/bin/bash

# Home:
# https://github.com/Pernat1y/arch-for-raspberry-pi/

# Docs:
# https://archlinuxarm.org/platforms/armv6/raspberry-pi
# https://archlinuxarm.org/platforms/armv7/broadcom/raspberry-pi-2
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-zero-2

# Uncomment for debug:
# set -x

# You can change size of the root partition
#root_size=3600
root_size=100%

# Get vars from args
rpi_ver=$1
dev=$2
part1=$dev"1"
part2=$dev"2"

# Show help
if [[ -z "$@" || "$@" == "-h"  || "$@" == "--help" ]]; then
    echo ''
    echo "Usage: $0 <rpi_version> <device>"
    echo ''
    echo ' <rpi_version>:'
    echo '    1 - ARMv6     [Raspberry Pi 1 / Zero]'
    echo '    2 - ARMv7/v8  [Raspberry Pi 2 / 3 / 4 / Zero 2]'
    echo '    3 - AArch64   [Raspberry Pi 3 / 4 / Zero 2]'
    echo ''
    echo ' <device> - disk to write image to. Something like /dev/sdX or /dev/mmcblkX'
    echo ''
    exit
fi

# Check for required tools
if ! command -v wget > /dev/null; then
    echo -e "I need those packages to be installed: \nwget bsdtar parted dosfstools \nExiting." && exit
fi

if ! command -v bsdtar > /dev/null; then
    echo -e "I need those packages to be installed: \nwget bsdtar parted dosfstools \nExiting." && exit
fi

if ! command -v parted > /dev/null; then
    echo -e "I need those packages to be installed: \nwget bsdtar parted dosfstools \nExiting." && exit
fi

# Check if root
if [ "$EUID" -ne 0 ]; then
    echo 'Needs to be root ro run this. Exiting.' && exit
fi

# Select RPi version
if [[ "$rpi_ver" -eq 1 ]]; then
    rootfs=ArchLinuxARM-rpi-latest.tar.gz
elif [[ "$rpi_ver" -eq 2 ]]; then
    rootfs=ArchLinuxARM-rpi-armv7-latest.tar.gz
elif [[ "$rpi_ver" -eq 3 ]]; then
    rootfs=ArchLinuxARM-rpi-aarch64-latest.tar.gz
else
    echo "RPi version can be in range 1-3. Exiting." && exit
fi

# Check device file
if [[ ! -b "$dev" ]]; then
    echo "No device selected or not special block file. Exiting." && exit
fi

# Check if device already mounted
if mount | grep -q "$dev"; then
    echo "Device or partition from $dev is already mounted. Exiting." && exit
fi

# Print device info
echo -e "\nTarget device is:"
fdisk -l "$dev" | head -n 2

# Create temp dir
temp_dir=$(mktemp -d)
echo -e "\nEntering working dir: $temp_dir"
if ! cd "$temp_dir"; then
    echo "Error while creating temp dir. Exiting." && exit
fi
mkdir boot root 2>/dev/null

if [[ ! -f "$rootfs" ]]; then
    echo -e "\nDownloading root FS."
    if ! wget --quiet --show-progress "http://os.archlinuxarm.org/os/""$rootfs"; then
        echo "Error while downloading FS. Exiting." && exit
    fi
    wget --quiet "http://os.archlinuxarm.org/os/""$rootfs"".md5"
else
    echo -e "\nRootfs already exist. Skipping download."
fi

echo -e "\nChecking image hash."
if ! md5sum --check "$rootfs"".md5" ; then
    echo "MD5 checksum failed for image. Exiting." && exit
fi

echo -e "\nCreating disk layout."
if ! parted --script "$dev" mklabel msdos; then
    echo "Error while creating disk layout. Exiting." && exit
fi

echo -e "\nCreating boot partition on $dev"
if ! parted --script "$dev" mkpart primary fat32 0 200; then
    echo "Error while creating disk layout for boot partition. Exiting." && exit
fi

echo "Setting boot flag on partition."
if ! parted --script "$dev" set 1 boot on; then
    echo "Error while setting boot flag on partition. Exiting." && exit
fi

echo -e "\nCreating root partition on $dev "
if ! parted --script "$dev" mkpart primary ext4 200 "$root_size"; then
    echo "Error while creating disk layout for root partition. Exiting." && exit
fi

echo -e "\nCreating boot file systems."
if ! mkfs.vfat "$part1" >/dev/null; then
    echo "Error while creating boot file system on $part1. Exiting." && exit
fi

echo -e "\nCreating root file systems."
if ! mkfs.ext4 "$part2" >/dev/null; then
    echo "Error while creating root file system on $part2. Exiting." && exit
fi

echo -e "\nMounting boot file system."
if ! mount "$part1" boot; then
    echo "Error while mounting $part1. Exiting." && exit
fi

echo -e "\nMounting root file system."
if ! mount "$part2" root; then
    echo "Error while mounting $part2. Exiting." && exit
fi

echo -e "\nUnpacking rootfs."
if ! bsdtar -xpf "$rootfs" -C root >/dev/null; then
    echo "Error while unpacking rootfs. Exiting." && exit
fi
sync && mv root/boot/* boot && sync

# Fix for AArch64 version
if [[ "$rpi_ver" -eq 5 ]]; then
    sed -i 's/mmcblk0/mmcblk1/g' root/etc/fstab
fi

echo -e "\nUnmounting file systems."
if ! umount boot root; then
    echo "Error while unmounting filesystems." && exit
fi

echo -e "\nCleaning up."
cd - && rm -r "$temp_dir"

echo -e "\nDone."

