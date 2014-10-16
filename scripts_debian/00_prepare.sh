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
INSTALLDIR="$(readlink -m mnt)"
umount_kill "$INSTALLDIR" || :

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
# Force overwrite of an existing image for now if debootstrap did not seem to complete...
# ------------------------------------------------------------------------------
debug "Determine if $IMG should be reused or deleted..."
if [ -f "$IMG" ]; then
    mount -o loop "$IMG" "$INSTALLDIR" || exit 1

    # Assume a failed debootstrap installation if .prepare_debootstrap does not exist
    if ! [ -f "$INSTALLDIR/tmp/.prepared_debootstrap" ]; then
        warn "Failed Image file $IMG already exists, deleting..."
        rm -f "$IMG"
    # Allow qubes to be updated
    elif [ -f "$INSTALLDIR/tmp/.prepared_qubes" ]; then
        rm "$INSTALLDIR/tmp/.prepared_qubes"
    fi

    # Umount image; don't fail if its already umounted
    umount_kill "$INSTALLDIR" || :
fi

# ------------------------------------------------------------------------------
# Execute any custom post configuration scripts
# ------------------------------------------------------------------------------
customStep "$0" "post"

