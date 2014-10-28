#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

#
# Whonix Post Install Steps (after qubes install)
#

# ------------------------------------------------------------------------------
# Source external scripts
# ------------------------------------------------------------------------------
. ${SCRIPTSDIR}/vars.sh

# ------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------
if [ "${VERBOSE}" -ge 2 -o "${DEBUG}" == "1" ]; then
    set -x
else
    set -e
fi

# ------------------------------------------------------------------------------
# Disable gnome network-manager since it will prevent networking
# ------------------------------------------------------------------------------
debug "Disabling gnome network-manager"
chroot "${INSTALLDIR}" systemctl disable network-manager
