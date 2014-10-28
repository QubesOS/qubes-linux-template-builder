#!/bin/bash -x
# vim: set ts=4 sw=4 sts=4 et :

################################################################################
# Allows a pre-built image to be used (if it exists) for installing
# Whonix.  This option is useful only for debugging Whonix installations
#
# To use, first create a regualr wheezy template and manually copy the prepared 
# image to debian-7-x64-prepard.img
#
# Example:
# cp ~/qubes-builder/qubes-src/linux-template-builder/prepared_images/debian-7-x64.img ~/qubes-builder/qubes-src/linux-template-builder/prepared_images/debian-7-x64-whonix-gateway-prepard.img
################################################################################

# ------------------------------------------------------------------------------
# Return if SNAPSHOT is not "1"
# ------------------------------------------------------------------------------
# This script is only used if SNAPSHOT is set
if [ ! "${SNAPSHOT}" == "1" ]; then
    exit 0
fi

# ------------------------------------------------------------------------------
# Source external scripts
# ------------------------------------------------------------------------------
. ${SCRIPTSDIR}/vars.sh
. ./umount_kill.sh >/dev/null

# ------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------
if [ "${VERBOSE}" -ge 2 -o "${DEBUG}" == "1" ]; then
    set -x
else
    set -e
fi

INSTALLDIR="$(readlink -m mnt)"

# ------------------------------------------------------------------------------
# Use a snapshot of the debootstraped debian image to install Whonix (for DEBUGGING)
# ------------------------------------------------------------------------------

manage_snapshot() {
    umount_kill "${INSTALLDIR}" || :

    mount -o loop "${IMG}" "${INSTALLDIR}" || exit 1
    # Remove old snapshots if whonix completed
    if [ -f "${INSTALLDIR}/tmp/.whonix_post" ]; then
        warn "Removing stale snapshots"
        umount_kill "${INSTALLDIR}" || :
        rm -rf "$debootstrap_snapshot"
        rm -rf "$updated_snapshot"
        return
    fi

    warn "Copying $1 to ${IMG}"
    mount -o loop "$1" "${INSTALLDIR}" || exit 1
    rm -f "${INSTALLDIR}/tmp/.prepared_groups"
    umount_kill "${INSTALLDIR}" || :
    cp -f "$1" "${IMG}"
}

splitPath "${IMG}" path_parts
debootstrap_snapshot="${path_parts[dir]}${path_parts[base]}-debootstrap${path_parts[dotext]}"
updated_snapshot="${path_parts[dir]}${path_parts[base]}-updated${path_parts[dotext]}"

if [ -f "$updated_snapshot" ]; then
    manage_snapshot "$updated_snapshot"
elif [ -f "$debootstrap_snapshot" ]; then
    manage_snapshot "$debootstrap_snapshot"
fi

