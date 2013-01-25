#!/bin/sh

echo "Mounting archlinux install system into archlinux_dvd..."
sudo mount root-image.fs archlinux_dvd

echo "--> Starting cleanup actions"
# Remove unused packages and their dependencies (make dependencies)
cleanuppkgs=`sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman -Qdt | cut -d " " -f 1`
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc $cleanuppkgs

# Remove yaourt dependencies
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc binutils yajl gcc make

# Clean pacman cache
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Scc

sudo umount archlinux_dvd

#rm -f $INSTALLDIR/var/lib/rpm/__db.00* $INSTALLDIR/var/lib/rpm/.rpm.lock
#yum -c $PWD/yum.conf $YUM_OPTS clean packages --installroot=$INSTALLDIR

# Make sure that rpm database has right format (for rpm version in template, not host)
#echo "--> Rebuilding rpm database..."
#chroot `pwd`/mnt /bin/rpm --rebuilddb 2> /dev/null
