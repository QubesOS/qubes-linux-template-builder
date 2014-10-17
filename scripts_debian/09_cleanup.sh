#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

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
# Execute any custom pre configuration scripts
# ------------------------------------------------------------------------------
customStep "$0" "pre"

# ------------------------------------------------------------------------------
# Cleanup any left over files from installation
# ------------------------------------------------------------------------------
rm -rf "INSTALLDIR/var/cache/apt/archives/*"
rm -f "$INSTALLDIR/etc/apt/sources.list.d/qubes-builder.list"
rm -f "$INSTALLDIR/etc/apt/trusted.gpg.d/qubes-builder.gpg"

# XXX: Whats this for?
rm -rf buildchroot

# ------------------------------------------------------------------------------
# Execute any custom post configuration scripts
# ------------------------------------------------------------------------------
customStep "$0" "post"
