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
# Set defualts for apt not to install recommended or extra packages
# ------------------------------------------------------------------------------
#read -r -d '' WHONIX_APT_PREFERENCES <<'EOF'
#Acquire::Languages "none";
#APT::Install-Recommends "false";
#APT::Install-Suggests "false";
#Dpkg::Options "--force-confold";
#EOF

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
    # Qubes needs a user named 'user'
    # --------------------------------------------------------------------------
    debug "Whonix Add user"
    chroot "${INSTALLDIR}" id -u 'user' >/dev/null 2>&1 || \
    {
        chroot "${INSTALLDIR}" groupadd -f user
        chroot "${INSTALLDIR}" useradd -g user -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev -m -s /bin/bash user
    }

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

    # ------------------------------------------------------------------------------
    # Create Whonix mount point
    # ------------------------------------------------------------------------------
    if ! [ -d "${INSTALLDIR}/home/user/Whonix" ]; then
        debug "Installing Whonix build environment..."
        chroot "${INSTALLDIR}" su user -c 'mkdir /home/user/Whonix'
    fi

    # --------------------------------------------------------------------------
    # Install Whonix code base
    # --------------------------------------------------------------------------
    if [ -d "${INSTALLDIR}/home/user/Whonix" ]; then
        debug "Building Whonix..."
        mount --bind "../Whonix" "${INSTALLDIR}/home/user/Whonix"
        sync
        sleep 1
    fi

    # ------------------------------------------------------------------------------
    # Determine type of Whonix build
    # ------------------------------------------------------------------------------
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

    # ------------------------------------------------------------------------------
    # Start Whonix build process
    # ------------------------------------------------------------------------------
    chroot "${INSTALLDIR}" su user -c "cd ~; ./whonix_build.sh ${BUILD_TYPE} ${DIST}" || { exit 1; }

    touch "${INSTALLDIR}/tmp/.whonix_installed"
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
