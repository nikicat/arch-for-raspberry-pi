# About
Script to write Arch Linux images for Raspberry Pi.

# Options
```
Usage: arch-for-raspberry-pi.sh <rpi_arch> <device>

 <rpi_arch>:
    1 - ARMv7/v8  [Raspberry Pi 2 / 3 / 4 / Zero 2]
    2 - AArch64   [Raspberry Pi 3 / 4 / Zero 2]

 <device> - disk to write image to. Something like /dev/sdX or /dev/mmcblkX

```

# Example
```
./arch-for-raspberry-pi.sh 5 /dev/sdX
```

# Download images
Prebuild images can be found in releases section:

https://github.com/Pernat1y/arch-for-raspberry-pi/releases

# Writing images to SD card
On Linux/Unix/BSD you can use dd:

```
dd if=ArchLinuxARM-rpi-2-latest.img of=/dev/sdX bs=2M status=progress
```

Output device file may be in form of '/dev/mmcblkX'. Make sure you have selected the right device before flashing!!

On Windows you can use one of those:

https://www.osforensics.com/tools/write-usb-images.html

https://sourceforge.net/projects/win32diskimager/

https://www.balena.io/etcher/

# Enable serial (TTL) port
If you want to enable serial, add following lines to config.txt file on 'boot' (fat16) partition:

```
dtoverlay=pi3-disable-bt
enable_uart=1
```

# Initialize the pacman keyring, populate the Arch Linux ARM package signing keys and update system
```
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu
```

# Resizing root partition
```
fdisk /dev/mmcblk0 # Delete partition 2, create new one with required size
resize2fs /dev/mmcblk0p2
```

