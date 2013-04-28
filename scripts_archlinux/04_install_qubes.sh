#!/bin/sh

set -e

echo "Mounting archlinux install system into mnt_archlinux_dvd..."
mkdir -p mnt_archlinux_dvd
sudo mount $CACHEDIR/root-image.fs mnt_archlinux_dvd

# Note: Enable x86 repos
su -c "echo '[multilib]' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'SigLevel = PackageRequired' >> $INSTALLDIR/etc/pacman.conf"
su -c "echo 'Include = /etc/pacman.d/mirrorlist' >> $INSTALLDIR/etc/pacman.conf"

echo "--> Registering Qubes custom repository"

sudo tee -a $INSTALLDIR/etc/pacman.conf <<EOF
[qubes]
SigLevel = Optional TrustAll
Server = file:///mnt/qubes-rpms-mirror-repo/pkgs
EOF

export CUSTOMREPO=$PWD/yum_repo_qubes/archlinux
sudo mkdir -p $INSTALLDIR/mnt/qubes-rpms-mirror-repo
sudo mount --bind $CUSTOMREPO $INSTALLDIR/mnt/qubes-rpms-mirror-repo

sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "cd /mnt/qubes-rpms-mirror-repo/;repo-add pkgs/qubes.db.tar.gz pkgs/*.pkg.tar.xz"

sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -Sy"

echo "--> Installing qubes-packages..."
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-xen"
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-core"
sudo ./mnt_archlinux_dvd/usr/bin/arch-chroot $INSTALLDIR sh -c "pacman -S --noconfirm qubes-vm-gui"

echo "--> Updating template fstab file..."
sudo su -c "echo '/dev/mapper/dmroot / ext4 defaults,noatime 1 1' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/dev/xvdb /rw ext4 defaults,noatime 1 2' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/dev/xvdc1 swap swap defaults 0 0' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/rw/home /home none noauto,bind,defaults 0 0' >> $INSTALLDIR/etc/fstab"
sudo su -c "echo '/dev/xvdd /usr/lib/modules ext3 defaults,noatime 0 0' >> $INSTALLDIR/etc/fstab"

echo "--> Cleaning up..."
sudo umount $INSTALLDIR/mnt/qubes-rpms-mirror-repo
sudo umount mnt_archlinux_dvd
