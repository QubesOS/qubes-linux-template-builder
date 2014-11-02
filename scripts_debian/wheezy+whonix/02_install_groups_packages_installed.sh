#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

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

# ------------------------------------------------------------------------------
# XXX: Create a snapshot - Only for DEBUGGING!
# ------------------------------------------------------------------------------
# Only execute if SNAPSHOT is set
if [ "${SNAPSHOT}" == "1" ]; then
    splitPath "${IMG}" path_parts
    PREPARED_IMG="${path_parts[dir]}${path_parts[base]}-updated${path_parts[dotext]}"

    if ! [ -f "${PREPARED_IMG}" ] && ! [ -f "${INSTALLDIR}/tmp/.whonix_prepared" ]; then
        umount_kill "${INSTALLDIR}" || :
        warn "Copying ${IMG} to ${PREPARED_IMG}"
        cp -f "${IMG}" "${PREPARED_IMG}"
        mount -o loop "${IMG}" "${INSTALLDIR}" || exit 1
        for fs in /dev /dev/pts /proc /sys /run; do mount -B $fs "${INSTALLDIR}/$fs"; done
    fi
fi

# ------------------------------------------------------------------------------
# chroot Whonix build script (Make sure set -e is not set)
# ------------------------------------------------------------------------------
read -r -d '' WHONIX_BUILD_SCRIPT <<'EOF'

################################################################################
# Pre Fixups
sudo mkdir -p /boot/grub2
sudo touch /boot/grub2/grub.cfg
sudo mkdir -p /boot/grub
sudo touch /boot/grub/grub.cfg
sudo mkdir --parents --mode=g+rw "/tmp/uwt"

# Whonix seems to re-install sysvinit even though there is a hold
# on the package.  Things seem to work anyway. BUT hopfully the
# hold on grub* don't get removed
sudo apt-mark hold sysvinit
sudo apt-mark hold grub-pc grub-pc-bin grub-common grub2-common

# Whonix expects haveged to be started
sudo /etc/init.d/haveged start

# Whonix does not always fix permissions after writing as sudo, especially
# when running whonixsetup so /var/lib/whonix/done_once is not readable by
# user, so set defualt umask for sudo
#sudo su -c 'echo "Defaults umask = 0002" >> /etc/sudoers'
#sudo su -c 'echo "Defaults umask_override" >> /etc/sudoers'

################################################################################
# Whonix installation
export WHONIX_BUILD_UNATTENDED_PKG_INSTALL="1"

pushd ~/Whonix
sudo ~/Whonix/whonix_build \
    --build $1 \
    --64bit-linux \
    --current-sources \
    --enable-whonix-apt-repository \
    --whonix-apt-repository-distribution $2 \
    --install-to-root \
    --skip-verifiable \
    --minimal-report \
    --skip-sanity-tests || { exit 1; }
popd
EOF

# ------------------------------------------------------------------------------
# Pin grub so it won't install
# ------------------------------------------------------------------------------
read -r -d '' WHONIX_APT_PIN <<'EOF'
Package: grub-pc
Pin: version *
Pin-Priority: -100

Package: grub-pc-bin
Pin: version *
Pin-Priority: -100

Package: grub-common
Pin: version *
Pin-Priority: -100

Package: grub2-common
Pin: version *
Pin-Priority: -100
EOF

# ------------------------------------------------------------------------------
# Set defualts for apt not to install recommended or extra packages
# ------------------------------------------------------------------------------
read -r -d '' WHONIX_APT_PREFERENCES <<'EOF'
Acquire::Languages "none";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Dpkg::Options "--force-confold";
EOF

# ------------------------------------------------------------------------------
# Cleanup function
# ------------------------------------------------------------------------------
function cleanup() {
    error "Whonix error; umounting ${INSTALLDIR} to prevent further writes"
    umount_kill "${INSTALLDIR}" || :
    exit 1
}
trap cleanup ERR
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Mount devices, etc required for Whonix installation
# ------------------------------------------------------------------------------
if ! [ -f "${INSTALLDIR}/tmp/.whonix_prepared" ]; then
    info "Preparing Whonix system"

    # --------------------------------------------------------------------------
    # Initialize Whonix submodules
    # --------------------------------------------------------------------------
    pushd "${WHONIX_DIR}"
    {
        su $(logname) -c "git submodule update --init --recursive";
    }
    popd

    # --------------------------------------------------------------------------
    # Patch Whonix submodules
    # --------------------------------------------------------------------------

    # Chekout a branch; create a branch first if it does not exist
    checkout_branch() {
        branch=$(git symbolic-ref --short -q HEAD)
        if ! [ "$branch" == "$1" ]; then
            su $(logname) -c git checkout "$1" >/dev/null 2>&1 || \
            { 
                su $(logname) -c git branch "$1"
                su $(logname) -c git checkout "$1"
            }
        fi
    }

    # sed search and replace. return 0 if replace happened, otherwise 1 
    search_replace() {
        local search="$1"
        local replace="$2"
        local file="$3"
        sed -i.bak '/'"$search"'/,${s//'"$replace"'/;b};$q1' "$file"
    }

    # Patch anon-meta-packages to not depend on grub-pc
    pushd "${WHONIX_DIR}"
    {
        search_replace "grub-pc" "" "grml_packages" || :
    }
    popd

    pushd "${WHONIX_DIR}/packages/anon-meta-packages/debian"
    {
        search1=" grub-pc,";
        replace="";

        #checkout_branch qubes
        search_replace "$search1" "$replace" control && \
        {
            cd "${WHONIX_DIR}/packages/anon-meta-packages";
            :
            #sudo -E -u $(logname) make deb-pkg || :
            #su $(logname) -c "dpkg-source --commit" || :
            #git add .
            #su $(logname) -c "git commit -am 'removed grub-pc depend'"
        } || :
    }
    popd

    pushd "${WHONIX_DIR}/packages/anon-shared-build-fix-grub/usr/lib/anon-dist/chroot-scripts-post.d"
    {
        search1="update-grub";
        replace=":";

        #checkout_branch qubes
        search_replace "$search1" "$replace" 85_update_grub && \
        {
            cd "${WHONIX_DIR}/packages/anon-shared-build-fix-grub";
            sudo -E -u $(logname) make deb-pkg || :
            su $(logname) -c "EDITOR=/bin/true dpkg-source -q --commit . no_grub";
            #git add . ;
            #su $(logname) -c "git commit -am 'removed grub-pc depend'"
        } || :
    }
    popd

    pushd "${WHONIX_DIR}/build-steps.d"
    {
        search1="   check_for_uncommited_changes";
        replace="   #check_for_uncommited_changes";

        search_replace "$search1" "$replace" 1200_create-debian-packages || :
    }
    popd

    # --------------------------------------------------------------------------
    # Whonix system config dependancies
    # --------------------------------------------------------------------------

    # Qubes needs a user named 'user'
    debug "Whonix Add user"
    chroot "${INSTALLDIR}" id -u 'user' >/dev/null 2>&1 || \
    {
        chroot "${INSTALLDIR}" groupadd -f user
        chroot "${INSTALLDIR}" useradd -g user -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev -m -s /bin/bash user
    }

    # Pin grub packages so they will not install
    echo "${WHONIX_APT_PIN}" > "${INSTALLDIR}/etc/apt/preferences.d/whonix_qubes"
    chmod 0644 "${INSTALLDIR}/etc/apt/preferences.d/whonix_qubes"

    # Install Whonix build scripts
    echo "${WHONIX_BUILD_SCRIPT}" > "${INSTALLDIR}/home/user/whonix_build.sh"
    chmod 0755 "${INSTALLDIR}/home/user/whonix_build.sh"

    # ------------------------------------------------------------------------------
    # Copy over any extra files
    # ------------------------------------------------------------------------------
    copyTree "files"

    touch "${INSTALLDIR}/tmp/.whonix_prepared"
fi

# ------------------------------------------------------------------------------
# Install Whonix
# ------------------------------------------------------------------------------
if [ -f "${INSTALLDIR}/tmp/.whonix_prepared" ] && ! [ -f "${INSTALLDIR}/tmp/.whonix_installed" ]; then
    info "Installing Whonix system"

    # --------------------------------------------------------------------------
    # Install Whonix code base
    # --------------------------------------------------------------------------
    if ! [ -d "${INSTALLDIR}/home/user/Whonix" ]; then
        debug "Installing Whonix build environment..."
        chroot "${INSTALLDIR}" su user -c 'mkdir /home/user/Whonix'
    fi

    if [ -d "${INSTALLDIR}/home/user/Whonix" ]; then
        debug "Building Whonix..."
        mount --bind "../Whonix" "${INSTALLDIR}/home/user/Whonix"
    fi

    if [ "${TEMPLATE_FLAVOR}" == "whonix-gateway" ]; then
        BUILD_TYPE="--torgateway"
    elif [ "${TEMPLATE_FLAVOR}" == "whonix-workstation" ]; then
        BUILD_TYPE="--torworkstation"
    else
        error "Incorrent Whonix type \"${TEMPLATE_FLAVOR}\" selected.  Not building Whonix modules"
        error "You need to set TEMPLATE_FLAVOR environment variable to either"
        error "whonix-gateway OR whonix-workstation"
        exit 1
    fi

    chroot "${INSTALLDIR}" su user -c "cd ~; ./whonix_build.sh ${BUILD_TYPE} ${DIST}" || { exit 1; }

    touch "${INSTALLDIR}/tmp/.whonix_installed"
fi

# ------------------------------------------------------------------------------
# Whonix Post Installation Configurations
# ------------------------------------------------------------------------------
if [ -f "${INSTALLDIR}/tmp/.whonix_installed" ] && ! [ -f "${INSTALLDIR}/tmp/.whonix_post" ]; then
    info "Post Configuring Whonix System"

    # Don't need Whonix interfaces; restore original
    pushd "${INSTALLDIR}/etc/network"
    {
        rm -f interfaces;
        ln -s interfaces.backup interfaces;
    }
    popd

    # Qubes installation will need a normal resolv.conf; will be restored back
    # in 04_qubes_install_post.sh within the wheezy+whonix-* directories
    pushd "${INSTALLDIR}/etc"
    {
        rm -f resolv.conf;
        cp -p resolv.conf.backup resolv.conf;
    }
    popd

    # Remove link to hosts file and copy original back
    # Will get set back to Whonix hosts file when the
    # /usr/lib/whonix/setup-ip is run on startup
    pushd "${INSTALLDIR}/etc"
    {
        rm -f hosts;
        cp -p hosts.anondist-orig hosts;
    }
    popd


    # Enable Tor
    #if [ "${TEMPLATE_FLAVOR}" == "whonix-gateway" ]; then
    #    sed -i 's/#DisableNetwork 0/DisableNetwork 0/g' "${INSTALLDIR}/etc/tor/torrc"
    #fi

    # Enable aliases in .bashrc
    sed -i "s/^# export/export/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^# eval/eval/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^# alias/alias/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^#force_color_prompt/force_color_prompt/g" "${INSTALLDIR}/home/user/.bashrc"
    sed -i "s/#alias/alias/g" "${INSTALLDIR}/home/user/.bashrc"
    sed -i "s/alias l='ls -CF'/alias l='ls -l'/g" "${INSTALLDIR}/home/user/.bashrc"

    # Fake that whonixsetup was already run
    #mkdir -p "${INSTALLDIR}/var/lib/whonix/do_once"
    #touch "${INSTALLDIR}/var/lib/whonix/do_once/whonixsetup.done"

    # Fake that initializer was already run
    mkdir -p "${INSTALLDIR}/root/.whonix"
    touch "${INSTALLDIR}/root/.whonix/first_run_initializer.done"

    # Prevent whonixcheck error
    echo 'WHONIXCHECK_NO_EXIT_ON_UNSUPPORTED_VIRTUALIZER="1"' >> "${INSTALLDIR}/etc/whonix.d/30_whonixcheck_default"

    # Use gdialog as an alternative for dialog
    mv -f "${INSTALLDIR}/usr/bin/dialog" "${INSTALLDIR}/usr/bin/dialog.dist"
    chroot "${INSTALLDIR}" update-alternatives --force --install /usr/bin/dialog dialog /usr/bin/gdialog 999

    # Disable unwanted applications
    chroot "${INSTALLDIR}" update-rc.d network-manager disable || :
    chroot "${INSTALLDIR}" update-rc.d spice-vdagent disable || :
    chroot "${INSTALLDIR}" update-rc.d swap-file-creator disable || :
    chroot "${INSTALLDIR}" update-rc.d whonix-initializer disable || :

    chroot "${INSTALLDIR}" service apt-cacher-ng stop || :
    chroot "${INSTALLDIR}" update-rc.d apt-cacher-ng disable || :

    # Tor will be re-enabled upon initial configuration
    chroot "${INSTALLDIR}" update-rc.d tor disable || :
    chroot "${INSTALLDIR}" update-rc.d sdwdate disable || :

    # Remove apt-cacher-ng
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot ${INSTALLDIR} apt-get.anondist-orig -y --force-yes remove --purge apt-cacher-ng

    # Remove original sources.list
    rm -f "${INSTALLDIR}/etc/apt/sources.list"

    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot ${INSTALLDIR} apt-get.anondist-orig update

    touch "${INSTALLDIR}/tmp/.whonix_post"
fi

# ------------------------------------------------------------------------------
# Execute any template flavor or sub flavor scripts
# ------------------------------------------------------------------------------
buildStep "99_custom_configuration.sh"

# ------------------------------------------------------------------------------
# Bring back original apt-get for installation of Qubues
# ------------------------------------------------------------------------------
pushd "${INSTALLDIR}/usr/bin" 
{
    rm -f apt-get;
    cp -p apt-get.anondist-orig apt-get;
}
popd

# ------------------------------------------------------------------------------
# Make sure the temporary policy-rc.d to prevent apt from starting services
# on package installation is still active; Whonix may have reset it
# ------------------------------------------------------------------------------
cat > "${INSTALLDIR}/usr/sbin/policy-rc.d" <<EOF
#!/bin/sh
return 101 # Action forbidden by policy
EOF
chmod 755 "${INSTALLDIR}/usr/sbin/policy-rc.d"

# ------------------------------------------------------------------------------
# Leave cleanup to calling function
# ------------------------------------------------------------------------------
trap - ERR EXIT
trap
