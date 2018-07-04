#!/bin/bash

#
# Docs:
# https://archlinuxarm.org/platforms/armv6/raspberry-pi
# https://archlinuxarm.org/platforms/armv7/broadcom/raspberry-pi-2
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3
#

rpi_ver=@1
dev=@2

if [[ -c "$dev" ]]; then
    echo ""
    echo "Usage:  <version> <device>"
    echo ""
    echo " <version> can be: "
    echo "  1 for Raspberry Pi Zero / Zero W / 1"
    echo "  2 for Raspberry Pi 2 / 3"
    echo "  3 for Raspberry Pi 3 / 3+"
    echo ""
    echo " <device> - disk to write image to. Something like /dev/sdX or /dev/mmcblkX"
    echo ""
    exit
fi

which wget bsdtar parted &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "I need 'wget', 'bsdtar' and 'parted' to be installed. Exiting."
    exit
fi

if [[ "$rpi_ver" -eq 1 ]]; then
    rootfs=ArchLinuxARM-rpi-latest.tar.gz
elif [[ "$rpi_ver" -eq 2 ]]; then
    rootfs=ArchLinuxARM-rpi-2-latest.tar.gz
elif [[ "$rpi_ver" -eq 3 ]]; then
    rootfs=ArchLinuxARM-rpi-3-latest.tar.gz
elif
    echo "RPi version can be in range 1-3. Exiting."
    exit
fi

if [[ -b "$dev" ]]; then
    echo "Selected device is not special block file. Exiting."
    exit
fi

dl_url="http://os.archlinuxarm.org/os/$rootfs"

temp_dir=`mktemp -d`

echo "Entering working dir: $temp_dir"
cd "$temp_dir"
mkdir boot root

echo "Downloading root FS."
wget --quiet --continue "http://os.archlinuxarm.org/os/""$rootfs"

echo "Creating disk layout."
parted --script "$dev" mklabel msdos
parted --script "$dev" mkpart primary ext4 0 100
parted --script "$dev" mkpart primary ext4 100 100%

echo "Creating file systems."
mkfs.ext4 "$dev""1"
mkfs.ext4 "$dev""2"

echo "Mounting file systems."
mount "$dev""1" boot
mount "$dev""2" root

echo "Unpacking rootfs."
bsdtar -xpf "$rootfs" -C root
sync
mv root/boot/* boot

echo "Unmounting file systems."
umount boot root

echo "Done."

