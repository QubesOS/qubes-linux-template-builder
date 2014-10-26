#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

#
# Whonix Post Install Steps (after qubes install)
#

# ------------------------------------------------------------------------------
# Source external scripts
# ------------------------------------------------------------------------------
. $SCRIPTSDIR/vars.sh

# ------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------
if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
else
    set -e
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
pushd "$INSTALLDIR/etc"
{
    rm -f resolv.conf
    cp -p resolv.conf.anondist resolv.conf
}
popd

# --------------------------------------------------------------------------
# Copy over any extra files that may be needed that are located in
# --------------------------------------------------------------------------
debug "Copy extra Qubes related files..." 
copyTree "extra-qubes-files"

touch "$INSTALLDIR/tmp/.prepared_qubes"

# ------------------------------------------------------------------------------
# Cleanup Whonix Installation
# ------------------------------------------------------------------------------
rm -rf "$INSTALLDIR"/home/user/Whonix
rm -rf "$INSTALLDIR"/home/user/whonix_binary
rm -f "$INSTALLDIR"/home/user/whonix_fix
rm -f "$INSTALLDIR"/home/user/whonix_build
