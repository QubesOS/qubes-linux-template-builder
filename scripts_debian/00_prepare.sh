#!/bin/bash -x
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
INSTALLDIR="$(readlink -m mnt)"
umount_kill "$INSTALLDIR" || :

# ------------------------------------------------------------------------------
# Execute any template flavor or sub flavor 'pre' scripts
# ------------------------------------------------------------------------------
buildStep "$0" "pre"

# ------------------------------------------------------------------------------
# Force overwrite of an existing image for now if debootstrap did not seem to complete...
# ------------------------------------------------------------------------------
debug "Determine if $IMG should be reused or deleted..."
if [ -f "$IMG" ]; then
    # Assume a failed debootstrap installation if .prepare_debootstrap does not exist
    mount -o loop "$IMG" "$INSTALLDIR" || exit 1
    if ! [ -f "$INSTALLDIR/tmp/.prepared_debootstrap" ]; then
        warn "Last build failed. Deleting $IMG"
        rm -f "$IMG"
    fi

    # Umount image; don't fail if its already umounted
    umount_kill "$INSTALLDIR" || :
fi

# ------------------------------------------------------------------------------
# Execute any template flavor or sub flavor 'post' scripts
# ------------------------------------------------------------------------------
buildStep "$0" "post"

