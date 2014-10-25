#!/bin/bash
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
# whonix-netvm-gateway contains last known IP used to search and replace
# ------------------------------------------------------------------------------
if [ -f "$INSTALLDIR/tmp/.prepared_whonix" -a ! -f "$INSTALLDIR/tmp/.prepared_whonix_custom_configurations" ]; then
    # --------------------------------------------------------------------------
    # Install Custom Configurations
    # --------------------------------------------------------------------------
    echo "10.152.152.10" > "$INSTALLDIR/etc/whonix-netvm-gateway"
    touch "$INSTALLDIR/tmp/.prepared_whonix_custom_configurations"
fi

# ------------------------------------------------------------------------------
# Remove apt-cacher-ng as it conflicts with something and is only for install
# ------------------------------------------------------------------------------
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    chroot "$INSTALLDIR" apt-get -y --force-yes remove apt-cacher-ng

# ------------------------------------------------------------------------------
# Remove original sources.list.  We will use one installed by Whonix now
# ------------------------------------------------------------------------------
rm -f "${INSTALLDIR}/etc/apt/sources.list"
