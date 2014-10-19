#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

# ------------------------------------------------------------------------------
# Return if SNAPSHOT is not "1"
# ------------------------------------------------------------------------------
# This script is only used if SNAPSHOT is set
if [ ! "$SNAPSHOT" == "1" ]; then
    exit 0
fi

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
# Create a snapshot of the already debootstraped image
# ------------------------------------------------------------------------------
splitPath "$IMG" path_parts
PREPARED_IMG="${path_parts[dir]}${path_parts[base]}-debootstrap${path_parts[dotext]}"

if ! [ -f "$PREPARED_IMG" ] && ! [ -f "$INSTALLDIR/tmp/.prepared_whonix" ]; then
    umount_kill "$INSTALLDIR" || :
    warn "Copying $IMG to $PREPARED_IMG"
    cp -f "$IMG" "$PREPARED_IMG"
    mount -o loop "$IMG" "$INSTALLDIR" || exit 1
fi
