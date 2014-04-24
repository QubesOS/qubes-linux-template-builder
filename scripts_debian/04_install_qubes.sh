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

echo "--> Installing qubes packages"
export CUSTOMREPO="$PWD/yum_repo_qubes/debian"
mkdir -p $INSTALLDIR/tmp/qubesdebs
find $CUSTOMREPO/apt -name '*.deb' -exec cp -t $INSTALLDIR/tmp/qubesdebs '{}' \;
chroot $INSTALLDIR /bin/sh -c 'dpkg -i /tmp/qubesdebs/*.deb'
rm -rf $INSTALLDIR/tmp/qubesdebs
# Install dependencies for qubes packages
chroot $INSTALLDIR apt-get -f -y install

# Remove temporary policy layer so services can start normally in the
# deployed template.
rm -f $BUILDCHROOT/usr/sbin/policy-rc.d

chroot $INSTALLDIR groupadd user
chroot $INSTALLDIR useradd -g user -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev -m -s /bin/bash user

echo "xen_netfront" >> $INSTALLDIR/etc/modules


# Kill any processes that might have been started by apt before unmounting
lsof $INSTALLDIR | tail -n +2 | awk '{print $2}' | xargs kill


