#!/bin/sh

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
sudo mount $CACHEDIR/root-image.fs mnt_archlinux_dvd

echo "--> Installing make dependencies..."
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c 'pacman -S --asdeps --needed --noconfirm binutils yajl gcc make'

#echo "--> Installing yaourt..."
#sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c 'cd tmp && wget https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz && tar xzvf package-query.tar.gz && cd package-query && makepkg --asroot && pacman --noconfirm -U package-query-*.pkg.tar.xz'
#sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c 'cd tmp && wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz && tar xzvf yaourt.tar.gz && cd yaourt && makepkg --asroot && pacman --noconfirm -U yaourt-*.pkg.tar.xz'

echo "--> Preparing build environment inside the chroot..."
# Notes for qubes-vm-xen
# Note: we need more ram for /tmp (at least 700M of disk space for compiling XEN because of the sources...)
sudo sed 's:-t tmpfs -o mode=1777,strictatime,nodev,:-t tmpfs -o size=700M,mode=1777,strictatime,nodev,:' -i ./mnt_archlinux_dvd/usr/bin/arch-chroot
sudo cp ./scripts_archlinux/build_package.sh $INSTALLDIR/etc/
sudo cp ./scripts_archlinux/CF8D4BBE.pub $INSTALLDIR/etc/
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "gpg --import /etc/CF8D4BBE.pub"

# Note: Enable x86 repos
su -c "echo '[multilib]' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALLDIR/etc/pacman.conf"
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -Sy"

echo "--> Compiling and installing qubes-packages..."
sudo cp ./scripts_archlinux/qubes-vm-xen.tar.gz.sig $INSTALLDIR/etc/package.sig
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR bash /etc/build_package.sh qubes-vm-xen
sudo cp ./scripts_archlinux/qubes-vm-core.tar.gz.sig $INSTALLDIR/etc/package.sig
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR bash /etc/build_package.sh qubes-vm-core
sudo cp ./scripts_archlinux/qubes-vm-gui.tar.gz.sig $INSTALLDIR/etc/package.sig
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR bash /etc/build_package.sh qubes-vm-gui
sudo cp ./scripts_archlinux/qubes-vm-kernel-modules.tar.gz.sig $INSTALLDIR/etc/package.sig
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR bash /etc/build_package.sh qubes-vm-kernel-modules

echo "--> Updating template fstab file..."
sudo su -c "echo '/dev/mapper/dmroot / ext4 defaults,noatime 1 1' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/dev/xvdb /rw ext4 defaults,noatime 1 2' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/dev/xvdc1 swap swap defaults 0 0' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/rw/home /home none noauto,bind,defaults 0 0' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/dev/xvdd /usr/lib/modules ext3 defaults,noatime 0 0' >> $INSTALLDIR/etc/fstab"

sudo umount mnt_archlinux_dvd
