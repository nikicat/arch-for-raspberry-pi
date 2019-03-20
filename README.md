# About
Script to write Arch Linux images for Raspberry Pi

# Usage
Usage: ./arch-for-raspberry-pi.sh <version> <device>

 <version> can be: 
  1 for Raspberry Pi Zero / Zero W / 1 (ARM v6) 
  2 for Raspberry Pi 2 / 3 (ARM v7) 
  3 for Raspberry Pi 3 / 3+ (ARM v8) 

 <device> - disk to write image to. Something like /dev/sdX or /dev/mmcblkX

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

