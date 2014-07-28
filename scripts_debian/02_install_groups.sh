#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

. $SCRIPTSDIR/vars.sh

# Set up a temporary policy-rc.d to prevent apt from starting services
# on package installation
cat > $BUILDCHROOT/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
return 101 # Action forbidden by policy
EOF
chmod 755 $BUILDCHROOT/usr/sbin/policy-rc.d

if [ "$DEBIANVERSION" = "wheezy" ]; then # stable
    echo "--> Adding debian-security repository."
    # security.debian.org only makes sense for stable/wheezy
    echo "deb http://security.debian.org/ ${DEBIANVERSION}/updates main" \
        >> "$INSTALLDIR/etc/apt/sources.list"
    echo "deb-src http://security.debian.org/ ${DEBIANVERSION}/updates main" \
        >> "$INSTALLDIR/etc/apt/sources.list"

    echo "--> Installing systemd"
    # sysvinit gives problems with qubes initramfs, we depend on systemd
    # for now. Apt *really* doesn't want to replace sysvinit in wheezy.
    # For jessie and newer, sysvinit is provided by sysvinit-core which
    # is not an essential package.
    echo 'Yes, do as I say!' | chroot $INSTALLDIR apt-get -y \
        --force-yes install systemd-sysv
else # testing/unstable
    echo "--> Installing systemd"
    chroot $INSTALLDIR apt-get -y install systemd-sysv
fi

chroot $INSTALLDIR systemctl set-default multi-user.target

echo "--> Upgrading system"
chroot $INSTALLDIR apt-get update
chroot $INSTALLDIR apt-get -y upgrade

echo "--> Setting keyboard layout"
chroot $INSTALLDIR debconf-set-selections <<EOF
keyboard-configuration  keyboard-configuration/variant  select  English (US)
keyboard-configuration  keyboard-configuration/layout   select  English (US)
keyboard-configuration  keyboard-configuration/model    select  Generic 105-key (Intl) PC
keyboard-configuration  keyboard-configuration/modelcode    string  pc105
keyboard-configuration  keyboard-configuration/layoutcode   string  us
keyboard-configuration  keyboard-configuration/variantcode  string  
keyboard-configuration  keyboard-configuration/optionscode  string  
EOF

echo "--> Installing extra packages"
xargs chroot $INSTALLDIR apt-get -y install < $SCRIPTSDIR/packages.list

# Remove temporary policy layer so services can start normally in the
# deployed template.
rm -f $BUILDCHROOT/usr/sbin/policy-rc.d

