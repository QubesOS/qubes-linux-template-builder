#!/bin/sh

echo "Mounting archlinux install system into archlinux_dvd..."
sudo mount root-image.fs archlinux_dvd

echo "-> Installing archlinux package groups..."
echo "-> Selected packages:"
echo "$PKGGROUPS"
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --needed --noconfirm -S $PKGGROUPS

sudo umount archlinux_dvd
