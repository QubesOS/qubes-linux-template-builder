#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mkdir -p mnt_archlinux_dvd
mount $CACHEDIR/root-image.fs mnt_archlinux_dvd

# Note: Enable x86 repos
su -c "echo '[multilib]' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALLDIR/etc/pacman.conf"

echo "--> Registering Qubes custom repository"

cat >> $INSTALLDIR/etc/pacman.conf <<EOF
[qubes]
SigLevel = Optional TrustAll
Server = file:///mnt/qubes-rpms-mirror-repo/pkgs
EOF

export CUSTOMREPO=$PWD/yum_repo_qubes/archlinux
mkdir -p $INSTALLDIR/mnt/qubes-rpms-mirror-repo
mount --bind $CUSTOMREPO $INSTALLDIR/mnt/qubes-rpms-mirror-repo

./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "cd /mnt/qubes-rpms-mirror-repo/;repo-add pkgs/qubes.db.tar.gz pkgs/*.pkg.tar.xz"

chown -R --reference=$CUSTOMREPO $CUSTOMREPO

./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -Sy"

echo "--> Installing qubes-packages..."
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-xen"
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-core"
./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-gui"

echo "--> Updating template fstab file..."
cat >> $INSTALLDIR/etc/fstab <<EOF
/dev/mapper/dmroot / ext4 defaults,noatime 1 1
/dev/xvdb /rw ext4 defaults,noatime 1 2
/dev/xvdc1 swap swap defaults 0 0
/rw/home /home none noauto,bind,defaults 0 0
/dev/xvdd /usr/lib/modules ext3 defaults,noatime 0 0
EOF

echo "--> Cleaning up..."
umount $INSTALLDIR/mnt/qubes-rpms-mirror-repo
umount mnt_archlinux_dvd
