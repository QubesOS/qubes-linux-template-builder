#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

#
# Whonix Post Install Steps (after qubes install)
#

# ------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------
. $SCRIPTSDIR/vars.sh

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

# ------------------------------------------------------------------------------
# Restore Whonix apt-get
# ------------------------------------------------------------------------------
if [ -L "$INSTALLDIR/usr/bin/apt-get" ]; then
    rm "$INSTALLDIR/usr/bin/apt-get"
    chroot "$INSTALLDIR" su -c "cd /usr/bin/; ln -s apt-get.anondist apt-get"
fi

# ------------------------------------------------------------------------------
# Restore Whonix sources
# ------------------------------------------------------------------------------
#if [ -L "$INSTALLDIR/etc/apt/sources.list.d" ]; then
#    rm -rf "$INSTALLDIR/etc/apt/sources.list.d"
#    mv "$INSTALLDIR/etc/apt/sources.list.d.qubes" "$INSTALLDIR/etc/apt/sources.list.d"
#fi

# ------------------------------------------------------------------------------
# Restore whonix resolv.conf
# ------------------------------------------------------------------------------
if [ -L "$INSTALLDIR/etc/resolv.conf" ]; then
    pushd "$INSTALLDIR/etc"
    sudo rm -f resolv.conf
    sudo ln -s resolv.conf.anondist resolv.conf
    popd
fi

# ------------------------------------------------------------------------------
# Copy over any extra files
# ------------------------------------------------------------------------------
echo "-> Copy extra files..." 
copy_dirs "extra-whonix-files"

# ------------------------------------------------------------------------------
# Cleanup Whonix Installation
# ------------------------------------------------------------------------------
rm -rf "$INSTALLDIR"/home/user/Whonix
rm -rf "$INSTALLDIR"/home/user/whonix_binary
rm -f "$INSTALLDIR"/home/user/whonix_fix
rm -f "$INSTALLDIR"/home/user/whonix_build
