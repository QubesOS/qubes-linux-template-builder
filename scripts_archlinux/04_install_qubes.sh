#!/bin/sh

echo "Mounting archlinux install system into archlinux_dvd..."
sudo mount root-image.fs archlinux_dvd

echo $INSTALLDIR
echo "--> Installing yaourt make dependencies..."
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c 'pacman -S --asdeps binutils yajl gcc make'

echo "--> Installing yaourt..."
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c 'cd tmp && wget https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz && tar xzvf package-query.tar.gz && cd package-query && makepkg --asroot && pacman --noconfirm -U package-query-*.pkg.tar.xz'
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c 'cd tmp && wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz && tar xzvf yaourt.tar.gz && cd yaourt && makepkg --asroot && pacman --noconfirm -U yaourt-*.pkg.tar.xz'

echo "--> Preparing build environment inside the chroot..."
# Notes for qubes-vm-xen
# Note: we need more ram for /tmp (at least 700M of disk space for compiling XEN because of the sources...)
sudo sed 's:-t tmpfs -o mode=1777,strictatime,nodev,:-t tmpfs -o size=700M,mode=1777,strictatime,nodev,:' -i ./archlinux_dvd/usr/bin/arch-chroot

# Note: Enable x86 repos
su -c "echo '[multilib]' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALLDIR/etc/pacman.conf"
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -Sy"

echo "--> Compiling and installing qubes-packages..."
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "yaourt --noconfirm -S qubes-vm-xen"
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "yaourt --noconfirm -S qubes-vm-core"
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "yaourt --noconfirm -S qubes-vm-gui"

sudo umount archlinux_dvd
