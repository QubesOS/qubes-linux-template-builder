#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

# ------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------
set -x

# ------------------------------------------------------------------------------
# Source external scripts
# ------------------------------------------------------------------------------
. $SCRIPTSDIR/vars.sh
. ./umount.sh >/dev/null

# ------------------------------------------------------------------------------
# If .prepared_groups has not been completed, don't continue
# ------------------------------------------------------------------------------
if ! [ -f "$INSTALLDIR/tmp/.prepared_groups" ]; then
    echo "--> prepared_groups installataion has not completed!... Exiting"
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

# ------------------------------------------------------------------------------
# Install Qubes Packages
# ------------------------------------------------------------------------------
if ! [ -f "$INSTALLDIR/tmp/.prepared_qubes" ]; then
    echo "--> Installing qbues modules"

    # --------------------------------------------------------------------------
    # Set up a temporary policy-rc.d to prevent apt from starting services
    # on package installation
    # --------------------------------------------------------------------------
    cat > "$INSTALLCHROOT/usr/sbin/policy-rc.d" <<EOF
#!/bin/sh
return 101 # Action forbidden by policy
EOF
    chmod 755 $INSTALLCHROOT/usr/sbin/policy-rc.d

    # --------------------------------------------------------------------------
    # Generate locales
    # --------------------------------------------------------------------------
    echo "--> Generate locales"
    echo "en_US.UTF-8 UTF-8" >> "$INSTALLDIR/etc/locale.gen"
    chroot "$INSTALLDIR" locale-gen
    chroot "$INSTALLDIR" update-locale LANG=en_US.UTF-8

    # --------------------------------------------------------------------------
    # Update /etc/fstab
    # --------------------------------------------------------------------------
    echo "--> Updating template fstab file..."
    cat >> "$INSTALLDIR/etc/fstab" <<EOF
/dev/mapper/dmroot /         ext4 defaults,noatime 1 1
/dev/xvdc1 swap              swap    defaults 0 0

/dev/xvdb /rw                ext4    noauto,defaults,discard 1 2
/rw/home /home               none    noauto,bind,defaults 0 0

tmpfs /dev/shm               tmpfs   defaults 0 0
devpts /dev/pts              devpts  gid=5,mode=620 0 0
proc /proc                   proc    defaults 0 0
sysfs /sys                   sysfs   defaults 0 0
xen /proc/xen                xenfs   defaults 0 0

/dev/xvdi /mnt/removable     auto    noauto,user,rw 0 0
/dev/xvdd /lib/modules       ext3    defaults 0 0
EOF

    # --------------------------------------------------------------------------
    # Link mtab
    # --------------------------------------------------------------------------
    rm -f "$INSTALLDIR/etc/mtab"
    ln -s "../proc/self/mounts" "$INSTALLDIR/etc/mtab"

    # --------------------------------------------------------------------------
    # Create modules directory
    # --------------------------------------------------------------------------
    mkdir -p "$INSTALLDIR/lib/modules"

    # --------------------------------------------------------------------------
    # Start of Qubes package installation
    # --------------------------------------------------------------------------
    echo "--> Installing qubes packages"
    export CUSTOMREPO="$PWD/yum_repo_qubes/$DIST"

    # --------------------------------------------------------------------------
    # Install keyrings
    # --------------------------------------------------------------------------
    if ! [ -e "$CACHEDIR/repo-secring.gpg" ]; then
        mkdir -p "$CACHEDIR"
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
        --secret-keyring "$CACHEDIR/repo-secring.gpg" \
        --keyring "$CACHEDIR/repo-pubring.gpg" \
        -o "$CUSTOMREPO/dists/$DIST/Release.gpg" \
        "$CUSTOMREPO/dists/$DIST/Release"
    cp "$CACHEDIR/repo-pubring.gpg" "$INSTALLDIR/etc/apt/trusted.gpg.d/qubes-builder.gpg"

    # --------------------------------------------------------------------------
    # Mount local qubes_repo
    # --------------------------------------------------------------------------
    mkdir -p "$INSTALLDIR/tmp/qubes_repo"
    mount --bind "$CUSTOMREPO" "$INSTALLDIR/tmp/qubes_repo"

    # --------------------------------------------------------------------------
    # Include qubes repo for apt
    # --------------------------------------------------------------------------
    cat > "$INSTALLDIR/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb file:/tmp/qubes_repo $DEBIANVERSION main
EOF

    # --------------------------------------------------------------------------
    # Update system; exit is not successful
    # --------------------------------------------------------------------------
    chroot "$INSTALLDIR" apt-get update || { umount "$INSTALLDIR/tmp/qubes_repo"; exit 1; }

    # --------------------------------------------------------------------------
    # Install Qubes packages
    # --------------------------------------------------------------------------
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot "$INSTALLDIR" apt-get -y --force-yes install `cat $SCRIPTSDIR/packages_qubes.list` || \
        { umount "$INSTALLDIR/tmp/qubes_repo"; exit 1; }

    # --------------------------------------------------------------------------
    # Remove Quebes repo from sources.list.d
    # --------------------------------------------------------------------------
    rm -f "$INSTALLDIR"/etc/apt/sources.list.d/qubes*.list
    umount "$INSTALLDIR/tmp/qubes_repo"
    rm -f "$INSTALLDIR/etc/apt/sources.list.d/qubes-builder.list"
    chroot "$INSTALLDIR" apt-get update || exit 1

    # --------------------------------------------------------------------------
    # Remove temporary policy layer so services can start normally in the
    # deployed template.
    # --------------------------------------------------------------------------
    rm -f "$BUILDCHROOT/usr/sbin/policy-rc.d"

    # --------------------------------------------------------------------------
    # Qubes needs a user named 'user'
    # --------------------------------------------------------------------------
    if chroot "$INSTALLDIR" id -u 'user' >/dev/null 2>&1; then
        :
    else
        chroot "$INSTALLDIR" groupadd -f user
        chroot "$INSTALLDIR" useradd -g user -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev -m -s /bin/bash user
    fi

    # --------------------------------------------------------------------------
    # Modules setup
    # --------------------------------------------------------------------------
    echo "xen_netfront" >> "$INSTALLDIR/etc/modules"

    # --------------------------------------------------------------------------
    # Remove `mesg` from root/.profile?
    # --------------------------------------------------------------------------
    sed -i -e '/^mesg n/d' "$INSTALLDIR/root/.profile"

    # --------------------------------------------------------------------------
    # Need a xen log directory or xen scripts will fail
    # --------------------------------------------------------------------------
    mkdir -p -m 0700 "$INSTALLDIR/var/log/xen"

    # --------------------------------------------------------------------------
    # Copy over any extra files that may be needed that are located in
    # $SCRIPT_DIR/extra-qubes-files
    # --------------------------------------------------------------------------
    echo "-> Copy extra files..." 
    copy_dirs "extra-qubes-files"

    touch "$INSTALLDIR/tmp/.prepared_qubes"
fi

# ------------------------------------------------------------------------------
# Execute any custom post configuration scripts
# ------------------------------------------------------------------------------
customStep "$0" "post"

# ------------------------------------------------------------------------------
# Kill all processes and umount all mounts within $INSTALLDIR, but not 
# $INSTALLDIR itself (extra '/' prevents $INSTALLDIR from being umounted itself)
# ------------------------------------------------------------------------------
umount_image "$INSTALLDIR/" || :

