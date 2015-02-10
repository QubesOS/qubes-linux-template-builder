#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source ./functions.sh >/dev/null
source ./umount_kill.sh >/dev/null

setVerboseMode
output "${bold}${under}INFO: ${SCRIPTSDIR}/distribution.sh imported by: ${0}${reset}"

# ==============================================================================
# Cleanup function
# ==============================================================================
function cleanup() {
    errval=$?
    trap - ERR EXIT
    trap
    error "${1:-"${0}: Error.  Cleaning up and un-mounting any existing mounts"}"
    umount_all || true

    # Return xtrace to original state
    [[ -n "${XTRACE}" ]] && [[ "${XTRACE}" -eq 0 ]] && set -x || set +x

    exit $errval
}

# ==============================================================================
# If .prepared_debootstrap has not been completed, don't continue
# ==============================================================================
function exitOnNoFile() {
    file="${1}"
    message="${2}"

    if ! [ -f "${file}" ]; then
        error "${message}"
        umount_all || true
        exit 1
    fi
}

# ==============================================================================
# Umount everthing within INSTALLDIR or $1 but kill all processes within first
# ==============================================================================
function umount_all() {
    directory="${1:-"${INSTALLDIR}"}"

    # Only remove dirvert policies, etc if base INSTALLDIR mount is being umounted
    if [ "${directory}" == "${INSTALLDIR}" -o "${directory}" == "${INSTALLDIR}/" ]; then
        if [ -n "$(mountPoints)" ]; then
            removeDbusUuid
            removeDivertPolicy
        fi
    fi

    if [ "${directory}" == "${INSTALLDIR}" -a "${LXC_ENABLE}" == "1" ]; then
        lxcStop
    fi

    umount_kill "${directory}" || true
}

# ==============================================================================
# Create snapshot
# ==============================================================================
function createSnapshot() {
    snapshot_name="${1}"

    if [ "${SNAPSHOT}" == "1" ]; then
        splitPath "${IMG}" path_parts
        snapshot_path="${path_parts[dir]}${path_parts[base]}-${snapshot_name}${path_parts[dotext]}"

        # create snapshot
        info "Creating snapshot of ${IMG} to ${snapshot_path}"
        sync
        cp -f "${IMG}" "${snapshot_path}"
    fi
}

# ==============================================================================
# Create DBUS uuid
# ==============================================================================
function createDbusUuid() {
    outputc green "Creating DBUS uuid..."
    removeDbusUuid
    if [ -e "${INSTALLDIR}/bin/dbus-uuidgen" ]; then
        chroot dbus-uuidgen --ensure 1>/dev/null 2>&1
    fi
}

# ==============================================================================
# Remove DBUS uuid
# ==============================================================================
function removeDbusUuid() {
    if [ -e "${INSTALLDIR}"/var/lib/dbus/machine-id ]; then
        outputc red "Removing generated machine uuid..."
        rm -f "${INSTALLDIR}/var/lib/dbus/machine-id"
    fi
}

# ==============================================================================
# Set up a temporary dpkg-divert policy to prevent apt from starting services
# on package installation
# ==============================================================================
function addDivertPolicy() {
    outputc green "Deactivating initctl..."
    chroot dpkg-divert --local --rename --add /sbin/initctl || true

    # Only move if its a regualr file; not soft link
    #if [ -f "${INSTALLDIR}/sbin/initctl" ]; then
    #    mv "${INSTALLDIR}"/sbin/initctl "${INSTALLDIR}"/sbin/initctl.dist
    #else
    #    rm -f "${INSTALLDIR}"/sbin/initctl || true
    #fi
    #chroot ln -fs /bin/true /sbin/initctl

    # utopic systemd install still broken...
    outputc green "Hacking invoke-rc.d to ignore missing init scripts..."
    chroot sed -i -e "s/exit 100/exit 0 #exit 100/" /usr/sbin/invoke-rc.d
}

# ==============================================================================
# Remove temporary dpkg-divert policy
# ==============================================================================
function removeDivertPolicy() {
    outputc red "Reactivating initctl..."

    #if [ -f "${INSTALLDIR}/sbin/initctl.dist" ]; then
    #    rm -f "${INSTALLDIR}"/sbin/initctl || true
    #    mv "${INSTALLDIR}"/sbin/initctl.dist "${INSTALLDIR}"/sbin/initctl
    #fi

    chroot dpkg-divert --local --rename --remove /sbin/initctl || true

    outputc red "Restoring invoke-rc.d..."
    chroot sed -i -e "s/exit 0 #exit 100/exit 100/" /usr/sbin/invoke-rc.d
}

# ==============================================================================
# Create system mount points
# ==============================================================================
function prepareChroot() {
    # Make sure nothing is mounted within $INSTALLDIR
    umount_kill "${INSTALLDIR}/"

    #mkdir -p "${INSTALLDIR}/lib/modules"
    #mount --bind /lib/modules "${INSTALLDIR}/lib/modules"

    if [ "${LXC_ENABLE}" == "1" ]; then
        # Shutdown lxc container if its running
        chroot echo && lxcStop || true

        # Start lxc container
        lxcStart
        sleep 3
        debug "lxc root: /proc/$(lxc-info -P "${LXC_DIR}" -n ${DIST} -p -H)/root"
    else
        mount -t tmpfs none "${INSTALLDIR}/run"
        if [ "${SYSTEMD_NSPAWN_ENABLE}"  != "1" ]; then
            #mount --bind /dev "${INSTALLDIR}/dev"
            ###mount --bind /dev/pts "${INSTALLDIR}/dev/pts"
            mount -t proc proc "${INSTALLDIR}/proc"
            mount -t sysfs sys "${INSTALLDIR}/sys"
        fi
        createDbusUuid
        addDivertPolicy
    fi

    # Does lxc need this; moving away for now
    ###createDbusUuid
}

# ==============================================================================
# apt-get upgrade
# ==============================================================================
function aptUpgrade() {
    aptUpdate
    #DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    #    chroot apt-get ${APT_GET_OPTIONS} upgrade
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot env APT_LISTCHANGES_FRONTEND=none apt-get dist-upgrade -u -y --force-yes
}

# ==============================================================================
# apt-get dist-upgrade
# ==============================================================================
function aptDistUpgrade() {
    aptUpdate
    #DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    #    chroot apt-get ${APT_GET_OPTIONS} dist-upgrade
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot env APT_LISTCHANGES_FRONTEND=none apt-get dist-upgrade -u -y --force-yes
}

# ==============================================================================
# apt-get update
# ==============================================================================
function aptUpdate() {
    debug "Updating system"
    #DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot apt-get update
}

# ==============================================================================
# apt-get remove
# ==============================================================================
function aptRemove() {
    files="$@"
    #DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot apt-get ${APT_GET_OPTIONS} remove ${files[@]}
}

# ==============================================================================
# apt-get install
# ==============================================================================
function aptInstall() {
    files="$@"
    #DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot apt-get ${APT_GET_OPTIONS} install ${files[@]}
}

# ==============================================================================
# Install extra packages in script_${DIST}/packages.list file
# -and / or- TEMPLATE_FLAVOR directories
# ==============================================================================
function installPackages() {
    if [ -n "${1}" ]; then
        # Locate packages within sub dirs
        if [ ${#@} == "1" ]; then
            getFileLocations packages_list "${1}" ""
        else
            packages_list="$@"
        fi
    else
        getFileLocations packages_list "packages.list" "${DIST}"
        if [ -z "${packages_list}" ]; then
            error "Can not locate a package.list file!"
            umount_all || true
            exit 1
        fi
    fi

    for package_list in ${packages_list[@]}; do
        debug "Installing extra packages from: ${package_list}"
        declare -a packages
        readarray -t packages < "${package_list}"

        info "Packages: "${packages[@]}""
        aptInstall "${packages[@]}" || return $?
    done
}

# ==============================================================================
# Install Systemd
# ==============================================================================
function installSystemd() {
    buildStep "$0" "pre-systemd"
    chroot apt-get update

    aptInstall systemd
    createDbusUuid

    # Set multi-user.target as default target
    chroot rm -f /etc/systemd/system/default.target
    chroot ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

    # XXX: TEMP lets see how stuff work with upstart in control for now
    # Boot using systemd
    chroot rm -f /sbin/init
    chroot ln -sf /lib/systemd/systemd /sbin/init

    if [ "${LXC_ENABLE}" == "1" ]; then
        # XXX: Patch resolvconf (may only be trusy specific; if so move into buildStep
        sed -i 's/RUN_CANONICALDIR/RUN_DIR/g' "${INSTALLDIR}/sbin/resolvconf"

        # Enable resolvconf
        chroot systemctl enable resolvconf

        # XXX: Do I really need to restart it?
        # Restart lxc container
        lxcRestart
    fi

    buildStep "$0" "post-systemd"
}

# ==============================================================================
# Destroy LXC container
# ==============================================================================
function lxcDestroy() {
    if [ "${LXC_ENABLE}" == "1" ]; then
        warn "Destroying LXC container..."
        lxc-destroy -P "${LXC_DIR}" -n "${DIST}" || true
        mkdir -p "${INSTALLDIR}"
    fi
}

# ==============================================================================
# Restart LXC container and wait for network
# ==============================================================================
function lxcRestart() {
    lxcStop
    lxcStart
    prepareChroot
}

# ==============================================================================
# Start LXC container and wait for network
# ==============================================================================
function lxcStart() {
    LXC_IF=eth0

    info "Launching lxc-wait in background..."
    lxc-wait -P "${LXC_DIR}" -n "${DIST}" -s RUNNING &
    lxc_wait_pid=$!

    info "Starting LXC container..."
    lxc-start -d -P "${LXC_DIR}" -n "${DIST}"

    info "Waiting for LXC container RUNNING state..."
    wait ${lxc_wait_pid}
    sleep 1

    info "Waiting for LXC container network ${LXC_IF} up state..."
    lxc-attach -P "${LXC_DIR}" -n "${DIST}" -- \
        su -c "while ! ip a | sed -rn '/: '"${LXC_IF}"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}' | grep -q '.'; do printf '.'; sleep 1; done; echo ''" || sleep 3

    info "Network state is active."

    # Re-map install directory to lxc container
    ###ORIG_INSTALLDIR="${INSTALLDIR}"
    ###INSTALLDIR="/proc/$(lxc-info -P "${LXC_DIR}" -n ${DIST} -p -H)/root"
}

# ==============================================================================
# Start LXC container and wait for network
# ==============================================================================
function lxcStop() {
    # XXX - Should not umount here in case of restart
    # umount anything in the lxc container (using _kill, not _all)
    umount_kill "${INSTALLDIR}/"

    # XXX: Is this needed
    #rm -rf "${INSTALLDIR}/run/*" | true

    # Re-set install directory to original location
    ###INSTALLDIR="${ORIG_INSTALLDIR-"${INSTALLDIR}"}"

    info "Launching lxc-wait in background..."
    lxc-wait -P "${LXC_DIR}" -n "${DIST}" -s STOPPED &
    lxc_wait_pid=$!

    info "Stopping LXC container..."
    sync
    lxc-stop --kill -P "${LXC_DIR}" -n "${DIST}" || true

    info "Waiting for LXC container STOPPED state..."
    wait ${lxc_wait_pid}
    sleep 1

    info "LXC container stopped."
}


# ==============================================================================
# ------------------------------------------------------------------------------
#                 C O N F I G U R A T I O N   R E L A T E D
# ------------------------------------------------------------------------------
# ==============================================================================

# ==============================================================================
# Add universe to sources.list
# ==============================================================================
function updateDebianSourceList() {
    # Add contrib and non-free component to repository
    touch "${INSTALLDIR}/etc/apt/sources.list"
    sed -i "s/${DIST} main$/${DIST} main contrib non-free/g" "${INSTALLDIR}/etc/apt/sources.list"

    # Add Debian security repositories
    source="deb http://security.debian.org ${DEBIANVERSION}/updates main"
    if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
        touch "${INSTALLDIR}/etc/apt/sources.list"
        echo "$source" >> "${INSTALLDIR}/etc/apt/sources.list"
    fi
    source="deb-src http://security.debian.org ${DEBIANVERSION}/updates main"
    if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
        touch "${INSTALLDIR}/etc/apt/sources.list"
        echo "$source" >> "${INSTALLDIR}/etc/apt/sources.list"
    fi
}

# ==============================================================================
# Add universe to sources.list
# ==============================================================================
function updateQubuntuSourceList() {
    sed -i "s/${DIST} main$/${DIST} main universe multiverse restricted/g" "${INSTALLDIR}/etc/apt/sources.list"
    source="deb http://archive.canonical.com/ubuntu ${DIST} partner"
    if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
        touch "${INSTALLDIR}/etc/apt/sources.list"
        echo "$source" >> "${INSTALLDIR}/etc/apt/sources.list"
    fi
    source="deb-src http://archive.canonical.com/ubuntu ${DIST} partner"
    if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
        touch "${INSTALLDIR}/etc/apt/sources.list"
        echo "$source" >> "${INSTALLDIR}/etc/apt/sources.list"
    fi
    chroot apt-get update
}

# ==============================================================================
# Make sure there is a resolv.conf with network of this AppVM for building
# ==============================================================================
function createResolvConf() {
    if [ "${LXC_ENABLE}" != "1" ]; then
        rm -f "${INSTALLDIR}/etc/resolv.conf"
        cp /etc/resolv.conf "${INSTALLDIR}/etc/resolv.conf"
    fi
}

# ==============================================================================
# Ensure umask set in /etc/login.defs is used (022)
# ==============================================================================
function configureUmask() {
    echo "session optional pam_umask.so" >> "${INSTALLDIR}/etc/pam.d/common-session"
}

# ==============================================================================
# Configure keyboard
# ==============================================================================
function configureKeyboard() {
    debug "Setting keyboard layout"
    cat > "${INSTALLDIR}/tmp/keyboard.conf" <<'EOF'
keyboard-configuration  keyboard-configuration/variant  select  English (US)
keyboard-configuration  keyboard-configuration/layout   select  English (US)
keyboard-configuration  keyboard-configuration/model    select  Generic 105-key (Intl) PC
keyboard-configuration  keyboard-configuration/modelcode    string  pc105
keyboard-configuration  keyboard-configuration/layoutcode   string  us
keyboard-configuration  keyboard-configuration/variantcode  string
keyboard-configuration  keyboard-configuration/optionscode  string
EOF
    chroot debconf-set-selections /tmp/keyboard.conf
}

# ==============================================================================
# Update locale
# ==============================================================================
function updateLocale() {
    debug "Updating locales"

    #echo "en_US.UTF-8 UTF-8" >> "${INSTALLDIR}/etc/locale.gen"
    #chroot "${INSTALLDIR}" locale-gen
    #chroot "${INSTALLDIR}" update-locale LANG=en_US.UTF-8

    chroot localedef -f UTF-8 -i en_US -c en_US.UTF-8
    chroot update-locale LC_ALL=en_US.UTF-8
}


# ==============================================================================
# ------------------------------------------------------------------------------
#           Q U B E S   S P E C I F I C   F U N C T I O N S
# ------------------------------------------------------------------------------
# ==============================================================================


# ==============================================================================
# Install Keyrings
# ==============================================================================
function installKeyrings() {
    if ! [ -e "${CACHEDIR}/repo-secring.gpg" ]; then
        mkdir -p "${CACHEDIR}"
        gpg --gen-key --batch <<EOF
Key-Type: RSA
Key-Length: 1024
Key-Usage: sign
Name-Real: Qubes builder
Expire-Date: 0
%pubring ${CACHEDIR}/repo-pubring.gpg
%secring ${CACHEDIR}/repo-secring.gpg
%commit
EOF
    fi

    if [ ! -e "${CUSTOMREPO}/dists/${DIST}/Release.gpg" ]; then
        gpg -abs --no-default-keyring \
            --secret-keyring "${CACHEDIR}/repo-secring.gpg" \
            --keyring "${CACHEDIR}/repo-pubring.gpg" \
            -o "${CUSTOMREPO}/dists/${DIST}/Release.gpg" \
            "${CUSTOMREPO}/dists/${DIST}/Release"
        cp "${CACHEDIR}/repo-pubring.gpg" "${INSTALLDIR}/etc/apt/trusted.gpg.d/qubes-builder.gpg"
    fi
}

# ==============================================================================
# Install Qubes Repo
# ==============================================================================
installQubesRepo() {
    info " Defining Qubes CUSTOMREPO Location: ${PWD}/yum_repo_qubes/${DIST}"
    export CUSTOMREPO="${PWD}/yum_repo_qubes/${DIST}"

#    info ' Installing keyrings' # Relies on $CUSTOMREPO
#    installKeyrings

    info "Mounting local qubes_repo"
    mkdir -p "${INSTALLDIR}/tmp/qubes_repo"
    mount --bind "${CUSTOMREPO}" "${INSTALLDIR}/tmp/qubes_repo"

    cat > "${INSTALLDIR}/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb file:/tmp/qubes_repo ${DIST} main
EOF

    # XXX: Moved keyring install last in process; not sure if mount was ready
    #      all the time in its previous place
    info ' Installing keyrings' # Relies on $CUSTOMREPO
    installKeyrings
}

# ==============================================================================
# Uninstall Qubes Repo
# ==============================================================================
uninstallQubesRepo() {
    info ' Removing Quebes build repo from sources.list.d'

    # Lets not umount; we do that anyway when 04 exits
    umount_kill "${INSTALLDIR}/tmp/qubes_repo"
    rm -f "${INSTALLDIR}/etc/apt/sources.list.d/qubes-builder.list"
}
