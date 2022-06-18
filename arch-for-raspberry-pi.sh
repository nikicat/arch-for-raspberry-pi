#!/usr/bin/bash -e

# Home:
# https://github.com/Pernat1y/arch-for-raspberry-pi/

# Docs:
# https://archlinuxarm.org/platforms/armv7/broadcom/raspberry-pi-2
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-zero-2
# https://archlinuxarm.org/forum/viewtopic.php?f=67&t=15422&start=20#p67299

# Uncomment for debug:
# set -x

# You can change size of the root partition
#root_size=3600
root_size=100%

# Get vars from args
rpi_arch=$1
dev=$2
part1=$dev"p1"
part2=$dev"p2"

# Show help
if [[ -z "$@" || "$@" == "-h"  || "$@" == "--help" ]]; then
    echo ''
    echo "Usage: $0 <rpi_arch> <device>"
    echo ''
    echo ' <rpi_arch>:'
    echo '    1 - ARMv7/v8  [Raspberry Pi 2 / 3 / 4 / Zero 2]'
    echo '    2 - AArch64   [Raspberry Pi 3 / 4 / Zero 2]'
    echo ''
    echo ' <device> - disk to write image to. Something like /dev/sdX or /dev/mmcblkX'
    echo ''
    exit
fi

mkdir -p root 2>/dev/null

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
if [[ "$rpi_arch" -eq 1 ]]; then
    rootfs=ArchLinuxARM-rpi-armv7-latest.tar.gz
elif [[ "$rpi_arch" -eq 2 ]]; then
    rootfs=ArchLinuxARM-rpi-aarch64-latest.tar.gz
else
    echo "RPi arch can be only 1 or 2. Exiting." && exit
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

if [[ ! -f "$rootfs" ]]; then
    echo -e "\nDownloading root FS."
    if ! wget --quiet --show-progress "http://os.archlinuxarm.org/os/""$rootfs"; then
        echo "Error while downloading FS. Exiting." && exit
    fi
else
    echo -e "\nRootfs already exist. Skipping download."
fi

if [[ ! -f "$rootfs"".md5" ]]; then
    wget --quiet "http://os.archlinuxarm.org/os/""$rootfs"".md5"
fi

echo "Checking image hash."
if ! md5sum --check "$rootfs"".md5" ; then
    echo "MD5 checksum failed for image. Remove '$rootfs' and/or '$rootfs.md5' and try again." && exit
fi

echo "Creating disk layout."
parted --script "$dev" mklabel msdos

echo "Creating boot partition on $dev"
parted --script "$dev" mkpart primary fat32 0% 200

echo "Setting boot flag on partition."
parted --script "$dev" set 1 boot on

echo "Creating root partition on $dev "
parted --script "$dev" mkpart primary ext4 200 "$root_size"

echo "Creating boot file system."
mkfs.vfat "$part1" >/dev/null

echo "Creating root file system."
mkfs.ext4 "$part2" >/dev/null

echo "Mounting root file system."
mount "$part2" root

mkdir root/boot

echo "Mounting boot file system."
mount "$part1" root/boot

echo "Unpacking rootfs."
bsdtar -xpf "$rootfs" -C root >/dev/null

echo "Patching boot.txt according to https://archlinuxarm.org/forum/viewtopic.php?f=67&t=15422&start=20#p67299"
cp boot.txt root/boot/boot.txt
(cd root/boot && ./mkscr)

echo "Unmounting file systems."
umount root/boot root

echo "Done."
