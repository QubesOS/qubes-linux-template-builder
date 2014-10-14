#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

# ------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------
. $SCRIPTSDIR/vars.sh
. ./umount.sh >/dev/null

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

if [ -f "$INSTALLDIR/tmp/.prepared_whonix" -a ! -f "$INSTALLDIR/tmp/.prepared_whonix_custom_configurations" ]; then
    # --------------------------------------------------------------------------
    # Install Custom Configurations
    # --------------------------------------------------------------------------
    echo "10.152.152.10" > "$INSTALLDIR/etc/whonix-netvm-gateway"
    touch "$INSTALLDIR/tmp/.prepared_whonix_custom_configurations"
fi
