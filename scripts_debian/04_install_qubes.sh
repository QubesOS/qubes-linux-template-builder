#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

. $SCRIPTSDIR/vars.sh

# Set up a temporary policy-rc.d to prevent apt from starting services
# on package installation
cat > $INSTALLCHROOT/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
return 101 # Action forbidden by policy
EOF
chmod 755 $INSTALLCHROOT/usr/sbin/policy-rc.d

echo "--> Generate locales"
echo "en_US.UTF-8 UTF-8" >> $INSTALLDIR/etc/locale.gen
chroot $INSTALLDIR locale-gen
chroot $INSTALLDIR update-locale LANG=en_US.UTF-8

echo "--> Updating template fstab file..."
cat >> $INSTALLDIR/etc/fstab <<EOF
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
/dev/mapper/dmroot / ext4 discard,noatime,errors=remount-ro 0 0
/dev/xvdb /rw ext4 noauto,discard,noatime,errors=remount-ro 0 0
/dev/xvdc1 swap swap defaults 0 0
/dev/xvdd /lib/modules ext3 defaults 0 0
xen /proc/xen xenfs defaults 0 0
/rw/home /home none noauto,bind,defaults 0 0
/dev/xvdi /mnt/removable auto noauto,user,rw 0 0
EOF

rm -f $INSTALLDIR/etc/mtab
ln -s ../proc/self/mounts $INSTALLDIR/etc/mtab

mkdir -p $INSTALLDIR/lib/modules

echo "--> Installing qubes packages"
export CUSTOMREPO="$PWD/yum_repo_qubes/$DIST"

if ! [ -e $CACHEDIR/repo-secring.gpg ]; then
    mkdir -p $CACHEDIR
    gpg --gen-key --batch <<EOF
Key-Type: RSA
Key-Length: 1024
Key-Usage: sign
Name-Real: Qubes builder
Expire-Date: 0
%pubring $CACHEDIR/repo-pubring.gpg
%secring $CACHEDIR/repo-secring.gpg
%commit
EOF
fi
gpg -abs --no-default-keyring \
        --secret-keyring $CACHEDIR/repo-secring.gpg \
        --keyring $CACHEDIR/repo-pubring.gpg \
        -o $CUSTOMREPO/dists/$DIST/Release.gpg \
        $CUSTOMREPO/dists/$DIST/Release

mkdir -p $INSTALLDIR/tmp/qubes_repo
mount --bind $CUSTOMREPO $INSTALLDIR/tmp/qubes_repo
cat > $INSTALLDIR/etc/apt/sources.list.d/qubes-builder.list <<EOF
deb file:/tmp/qubes_repo $DEBIANVERSION main
EOF
cp $CACHEDIR/repo-pubring.gpg $INSTALLDIR/etc/apt/trusted.gpg.d/qubes-builder.gpg

chroot $INSTALLDIR apt-get update || { umount $INSTALLDIR/tmp/qubes_repo; exit 1; }
chroot $INSTALLDIR apt-get -y install `cat $SCRIPTSDIR/packages_qubes.list` || { umount $INSTALLDIR/tmp/qubes_repo; exit 1; }
umount $INSTALLDIR/tmp/qubes_repo
rm -f $INSTALLDIR/etc/apt/sources.list.d/qubes-builder.list
chroot $INSTALLDIR apt-get update || exit 1

# Remove temporary policy layer so services can start normally in the
# deployed template.
rm -f $BUILDCHROOT/usr/sbin/policy-rc.d

chroot $INSTALLDIR groupadd user
chroot $INSTALLDIR useradd -g user -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev -m -s /bin/bash user

echo "xen_netfront" >> $INSTALLDIR/etc/modules

sed -i -e '/^mesg n/d' $INSTALLDIR/root/.profile

# Kill any processes that might have been started by apt before unmounting
lsof $INSTALLDIR | tail -n +2 | awk '{print $2}' | xargs --no-run-if-empty kill


