#!/bin/sh

echo "Mounting archlinux install system into archlinux_dvd..."
sudo mount root-image.fs archlinux_dvd

echo "Creating chroot bootstrap environment"

sudo mount --bind $INSTALLDIR archlinux_dvd/mnt
sudo cp /etc/resolv.conf archlinux_dvd/etc

echo "-> Initializing pacman keychain"
sudo ./archlinux_dvd/usr/bin/arch-chroot archlinux_dvd/ pacman-key --init
sudo ./archlinux_dvd/usr/bin/arch-chroot archlinux_dvd/ pacman-key --populate

echo "-> Installing core pacman packages..."
sudo ./archlinux_dvd/usr/bin/arch-chroot archlinux_dvd/ sh -c 'pacstrap /mnt base'

echo "-> Cleaning up bootstrap environment"
sudo umount archlinux_dvd/mnt

sudo umount archlinux_dvd

cp scripts_"${DIST}"/resolv.conf $INSTALLDIR/etc
