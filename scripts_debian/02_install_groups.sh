#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

# ------------------------------------------------------------------------------
# Source external scripts
# ------------------------------------------------------------------------------
. $SCRIPTSDIR/vars.sh
. ./umount_kill.sh >/dev/null

# ------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------
if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
else
    set -e
fi

# ------------------------------------------------------------------------------
# If .prepared_debootstrap has not been completed, don't continue
# ------------------------------------------------------------------------------
if ! [ -f "$INSTALLDIR/tmp/.prepared_debootstrap" ]; then
    error "prepared_debootstrap installataion has not completed!... Exiting"
    umount_kill "$INSTALLDIR" || :
    exit 1
fi

# ------------------------------------------------------------------------------
# Mount system mount points
# ------------------------------------------------------------------------------
for fs in /dev /dev/pts /proc /sys /run; do mount -B $fs "$INSTALLDIR/$fs"; done

# ------------------------------------------------------------------------------
# Execute any custom pre configuration scripts
# ------------------------------------------------------------------------------
customStep "$0" "pre"

if ! [ -f "$INSTALLDIR/tmp/.prepared_groups" ]; then
    # ------------------------------------------------------------------------------
    # Cleanup function
    # ------------------------------------------------------------------------------
    function cleanup() {
        error "Install groups error and umount"
        rm -f "$INSTALLDIR/usr/sbin/policy-rc.d"
        umount_kill "$INSTALLDIR" || :
        exit 1
    }
    trap cleanup ERR
    trap cleanup EXIT

    # ------------------------------------------------------------------------------
    # Set up a temporary policy-rc.d to prevent apt from starting services
    # on package installation
    # ------------------------------------------------------------------------------
    cat > "$INSTALLDIR/usr/sbin/policy-rc.d" <<EOF
#!/bin/sh
return 101 # Action forbidden by policy
EOF
    chmod 755 "$INSTALLDIR/usr/sbin/policy-rc.d"

    # ------------------------------------------------------------------------------
    # Add debian security repository
    # ------------------------------------------------------------------------------
    debug "Adding debian-security repository."
    source="deb http://security.debian.org ${DEBIANVERSION}/updates main"
    if ! grep -r -q "$source" "$INSTALLDIR/etc/apt/sources.list"*; then
        touch "$INSTALLDIR/etc/apt/sources.list"
        echo "$source" >> "$INSTALLDIR/etc/apt/sources.list"
    fi
    source="deb-src http://security.debian.org ${DEBIANVERSION}/updates main"
    if ! grep -r -q "$source" "$INSTALLDIR/etc/apt/sources.list"*; then
        touch "$INSTALLDIR/etc/apt/sources.list"
        echo "$source" >> "$INSTALLDIR/etc/apt/sources.list"
    fi

    # ------------------------------------------------------------------------------
    # Upgrade system
    # ------------------------------------------------------------------------------
    debug "Upgrading system"
    chroot "$INSTALLDIR" apt-get update
    true "${stout}"
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot "$INSTALLDIR" apt-get -y --force-yes dist-upgrade

    # ------------------------------------------------------------------------------
    # Configure keyboard
    # ------------------------------------------------------------------------------
    debug "Setting keyboard layout"
    chroot "$INSTALLDIR" debconf-set-selections <<EOF
keyboard-configuration  keyboard-configuration/variant  select  English (US)
keyboard-configuration  keyboard-configuration/layout   select  English (US)
keyboard-configuration  keyboard-configuration/model    select  Generic 105-key (Intl) PC
keyboard-configuration  keyboard-configuration/modelcode    string  pc105
keyboard-configuration  keyboard-configuration/layoutcode   string  us
keyboard-configuration  keyboard-configuration/variantcode  string
keyboard-configuration  keyboard-configuration/optionscode  string
EOF

    # ------------------------------------------------------------------------------
    # Install extra packages in script_$DEBIANVERSION/packages.list file
    # ------------------------------------------------------------------------------
    if [ -n "${TEMPLATE_FLAVOR}" ]; then
        PKGLISTFILE="$SCRIPTSDIR/packages_${DIST}_${TEMPLATE_FLAVOR}.list"
        if ! [ -r "${PKGLISTFILE}" ]; then
            error "ERROR: ${PKGLISTFILE} does not exists!"
            umount_kill "$INSTALLDIR" || :
            exit 1
        fi
    elif [ -r "$SCRIPTSDIR/packages_${DIST}.list" ]; then
        PKGLISTFILE="$SCRIPTSDIR/packages_${DIST}.list"
    else
        PKGLISTFILE="$SCRIPTSDIR/packages.list"
    fi

    debug "Installing extra packages"
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        xargs chroot $INSTALLDIR apt-get -y --force-yes install < "$PKGLISTFILE"

    # ------------------------------------------------------------------------------
    # Execute any custom configuration scripts after file packages installed
    # (Whonix needs dependancies installed before installation)
    # ------------------------------------------------------------------------------
    customStep "$0" "packages_installed"

    # ------------------------------------------------------------------------------
    # Install systemd
    # ------------------------------------------------------------------------------
    # - sysvinit gives problems with qubes initramfs, we depend on systemd
    #   for now. Apt *really* doesn't want to replace sysvinit in wheezy.
    #   For jessie and newer, sysvinit is provided by sysvinit-core which
    #   is not an essential package.
    # ------------------------------------------------------------------------------
    debug "Installing systemd for debian ($DEBIANVERSION)"
    if [ "$DEBIANVERSION" == "wheezy" ]; then
        echo 'Yes, do as I say!' | DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
            chroot "$INSTALLDIR" apt-get -y --force-yes remove sysvinit
    else
        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
            chroot "$INSTALLDIR" apt-get -y --force-yes remove sysvinit
    fi

    # Prevent sysvinit from being re-installed
    debug "Preventing sysvinit re-installation"
    chroot "$INSTALLDIR" apt-mark hold sysvinit

    # Pin sysvinit to prevent being re-installed 
    cat > "$INSTALLDIR/etc/apt/preferences.d/qubes_sysvinit" <<EOF
Package: sysvinit
Pin: version *
Pin-Priority: -100
EOF
    chmod 0644 "$INSTALLDIR/etc/apt/preferences.d/qubes_sysvinit"

    chroot "$INSTALLDIR" apt-get update
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot "$INSTALLDIR" apt-get -y --force-yes install systemd-sysv

    # ------------------------------------------------------------------------------
    # Set multu-user.target as the default target (runlevel 3)
    # ------------------------------------------------------------------------------
    #chroot "$INSTALLDIR" systemctl set-default multi-user.target
    chroot "$INSTALLDIR" rm -f /etc/systemd/system/default.target
    chroot "$INSTALLDIR" ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
    
    # ------------------------------------------------------------------------------
    # Qubes is now being built with some SID packages; grab backport for wheezy
    # ------------------------------------------------------------------------------
    if [ "$DEBIANVERSION" == "wheezy" ]; then
        debug "Adding wheezy backports repository."
        source="deb ${DEBIAN_MIRROR} wheezy-backports main"
        if ! grep -r -q "$source" "$INSTALLDIR/etc/apt/sources.list"*; then
            touch "$INSTALLDIR/etc/apt/sources.list"
            echo "$source" >> "$INSTALLDIR/etc/apt/sources.list"
        fi
        chroot $INSTALLDIR apt-get update
        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
            chroot $INSTALLDIR apt-get -y --force-yes -t wheezy-backports install init-system-helpers
    fi

    # ------------------------------------------------------------------------------
    # Cleanup
    # ------------------------------------------------------------------------------
    # Remove temporary policy layer so services can start normally in the
    # deployed template.
    rm -f "$INSTALLDIR/usr/sbin/policy-rc.d"
    touch "$INSTALLDIR/tmp/.prepared_groups"
    trap - ERR EXIT
    trap

    # Kill all processes and umount all mounts within $INSTALLDIR, 
    # but not $INSTALLDIR itself (extra '/' prevents $INSTALLDIR from being
    # umounted itself)
    umount_kill "$INSTALLDIR/" || :
fi

# ------------------------------------------------------------------------------
# Execute any custom post configuration scripts
# ------------------------------------------------------------------------------
customStep "$0" "post"

