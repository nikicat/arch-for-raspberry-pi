# About
Script to write Arch Linux images for Raspberry Pi

# Usage
./arch-for-raspberry-pi.sh --help

# Download images
Prebuild images can be found in releases section:

https://github.com/Pernat1y/arch-for-raspberry-pi/releases

# Writing images to SD card
On Linux/Unix/BSD you can use dd:

dd if=ArchLinuxARM-rpi-2-latest.img of=/dev/sdX bs=2M status=progress

Output device file may be in form of '/dev/mmcblkX'. Make sure you have selected the right device before flashing!!

On Windows you can use one of those:

https://www.osforensics.com/tools/write-usb-images.html

https://sourceforge.net/projects/win32diskimager/

https://www.balena.io/etcher/

# Enabling serial port (USB to TTL serial)
If you want to enable serial, add following lines to config.txt file on 'boot' (fat16) partition:

dtoverlay=pi3-disable-bt

enable_uart=1

# Initialize the pacman keyring, populate the Arch Linux ARM package signing keys and update system
pacman -Scc

rm -r /var/lib/pacman/sync /etc/pacman.d/gnupg

pacman-key --init

pacman-key --populate archlinuxarm

pacman -Syu

# Resize root partition
fdisk /dev/mmcblk0 # Delete partition 2, create new one with new size

resize2fs /dev/mmcblk0p2

