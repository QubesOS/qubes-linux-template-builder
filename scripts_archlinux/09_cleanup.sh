#!/bin/sh

echo "Mounting archlinux install system into archlinux_dvd..."
sudo mount root-image.fs archlinux_dvd

echo "--> Starting cleanup actions"
# Remove unused packages and their dependencies (make dependencies)
cleanuppkgs=`sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman -Qdt | cut -d " " -f 1`
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Rsc $cleanuppkgs

# Clean pacman cache
sudo ./archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR pacman --noconfirm -Scc

# Remove build data
rm $INSTALLDIR/etc/build_package.sh
rm $INSTALLDIR/etc/CF8D4BBE.pub
rm $INSTALLDIR/etc/package.sig

sudo umount archlinux_dvd

#rm -f $INSTALLDIR/var/lib/rpm/__db.00* $INSTALLDIR/var/lib/rpm/.rpm.lock
#yum -c $PWD/yum.conf $YUM_OPTS clean packages --installroot=$INSTALLDIR

# Make sure that rpm database has right format (for rpm version in template, not host)
#echo "--> Rebuilding rpm database..."
#chroot `pwd`/mnt /bin/rpm --rebuilddb 2> /dev/null
