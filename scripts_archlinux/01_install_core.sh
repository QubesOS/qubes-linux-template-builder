#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mkdir -p mnt_archlinux_dvd
mount $CACHEDIR/root-image.fs mnt_archlinux_dvd

echo "Creating chroot bootstrap environment"

mount --bind $INSTALLDIR mnt_archlinux_dvd/mnt
cp /etc/resolv.conf mnt_archlinux_dvd/etc

echo "-> Initializing pacman keychain"
./mnt_archlinux_dvd/usr/bin/arch-chroot mnt_archlinux_dvd/ pacman-key --init
./mnt_archlinux_dvd/usr/bin/arch-chroot mnt_archlinux_dvd/ pacman-key --populate

echo "-> Installing core pacman packages..."
./mnt_archlinux_dvd/usr/bin/arch-chroot mnt_archlinux_dvd/ sh -c 'pacstrap /mnt base'

echo "--> Removing non required linux kernel (can be added manually through a package)"
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc linux

echo "-> Cleaning up bootstrap environment"
umount mnt_archlinux_dvd/mnt

umount mnt_archlinux_dvd

cp $SCRIPTSDIR/resolv.conf $INSTALLDIR/etc
