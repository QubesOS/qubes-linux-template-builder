#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mount $CACHEDIR/root-image.fs mnt_archlinux_dvd

PKGGROUPS=`cat $SCRIPTSDIR/packages.list`

echo "-> Installing archlinux package groups..."
echo "-> Selected packages:"
echo "$PKGGROUPS"
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --needed --noconfirm -S $PKGGROUPS

umount mnt_archlinux_dvd
