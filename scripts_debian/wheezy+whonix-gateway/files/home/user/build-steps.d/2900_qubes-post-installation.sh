#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

# ------------------------------------------------------------------------------
# Whonix Post Installation Configurations
# ------------------------------------------------------------------------------
echo "Post Configuring Whonix System"

pushd "/etc/network"
{
    rm -f interfaces;
    ln -s interfaces.backup interfaces;
}
popd

pushd "/etc"
{
    rm -f resolv.conf;
    cp -p resolv.conf.backup resolv.conf;
}
popd

# Enable Tor
#if [ "${TEMPLATE_FLAVOR}" == "whonix-gateway" ]; then
#    sed -i 's/#DisableNetwork 0/DisableNetwork 0/g' "/etc/tor/torrc"
#fi

# Fake that whonixsetup was already run
#mkdir -p "/var/lib/whonix/do_once"
#touch "/var/lib/whonix/do_once/whonixsetup.done"

# Fake that initializer was already run
mkdir -p "/root/.whonix"
touch "/root/.whonix/first_run_initializer.done"

# Prevent whonixcheck error
echo 'WHONIXCHECK_NO_EXIT_ON_UNSUPPORTED_VIRTUALIZER="1"' >> "/etc/whonix.d/30_whonixcheck_default"

# Use gdialog as an alternative for dialog
update-alternatives --install /usr/bin/dialog dialog /usr/bin/gdialog 999

# Disable unwanted applications
update-rc.d network-manager disable || :
update-rc.d spice-vdagent disable || :
update-rc.d swap-file-creator disable || :
update-rc.d whonix-initializer disable || :

service apt-cacher-ng stop || :
update-rc.d apt-cacher-ng disable || :

# Remove apt-cacher-ng
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    apt-get.anondist-orig -y --force-yes remove --purge apt-cacher-ng

# Remove original sources.list
rm -f "/etc/apt/sources.list"

DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    apt-get.anondist-orig update

