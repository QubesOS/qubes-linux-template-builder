#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
sudo mount $CACHEDIR/root-image.fs mnt_archlinux_dvd

echo "Creating chroot bootstrap environment"

sudo mount --bind $INSTALLDIR mnt_archlinux_dvd/mnt
sudo cp /etc/resolv.conf mnt_archlinux_dvd/etc

echo "-> Initializing pacman keychain"
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot mnt_archlinux_dvd/ pacman-key --init
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot mnt_archlinux_dvd/ pacman-key --populate

echo "-> Installing core pacman packages..."
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot mnt_archlinux_dvd/ sh -c 'pacstrap /mnt base'

echo "-> Cleaning up bootstrap environment"
sudo umount mnt_archlinux_dvd/mnt

sudo umount mnt_archlinux_dvd

cp $SCRIPTSDIR/resolv.conf $INSTALLDIR/etc
