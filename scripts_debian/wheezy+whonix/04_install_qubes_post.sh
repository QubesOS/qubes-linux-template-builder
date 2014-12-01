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
# Enable Qubes-Whonix services
# ------------------------------------------------------------------------------
chroot "${INSTALLDIR}" systemctl disable qubes-whonix-network.service || :
chroot "${INSTALLDIR}" systemctl enable qubes-whonix-network.service || :

chroot "${INSTALLDIR}" systemctl disable qubes-whonix-firewall.service || :
chroot "${INSTALLDIR}" systemctl enable qubes-whonix-firewall.service || :

chroot "${INSTALLDIR}" systemctl enable qubes-whonix-init.service || :

# ------------------------------------------------------------------------------
# Restore Whonix apt-get
# ------------------------------------------------------------------------------
pushd "${INSTALLDIR}/usr/bin" 
{
    rm -f apt-get;
    cp -p apt-get.anondist apt-get;
}
popd

# ------------------------------------------------------------------------------
# Restore whonix resolv.conf
# ------------------------------------------------------------------------------
pushd "${INSTALLDIR}/etc"
{
    rm -f resolv.conf;
    cp -p resolv.conf.anondist resolv.conf;
}
popd

# ------------------------------------------------------------------------------
# Cleanup Whonix Installation
# ------------------------------------------------------------------------------
rm -rf "${INSTALLDIR}"/home/user/Whonix
rm -rf "${INSTALLDIR}"/home/user/whonix_binary
rm -f "${INSTALLDIR}"/home/user/whonix_fix
rm -f "${INSTALLDIR}"/home/user/whonix_build.sh
