#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

#
# Written by Jason Mehring (nrgaway@gmail.com)
#

# Kills any processes within the mounted location and
# unmounts any mounts active within.
#
# To keep the actual mount mounted, add a '/' to end
#
# ${1}: directory to umount
#
# Examples:
# To kill all processes and mounts within 'chroot-jessie' but keep
# 'chroot-jessie' mounted:
#
# ./umount_kill.sh chroot-jessie/
#
# To kill all processes and mounts within 'chroot-jessie' AND also
# umount 'chroot-jessie' mount:
#
# ./umount_kill.sh chroot-jessie
#

. ./functions.sh

mountPoint() {
    local mount_point="${1}"

    # We need absolute paths here so we don't kill everything
    if ! [[ "${mount_point}" = /* ]]; then
	    mount_point="$(readlink -m .)/${mount_point}"
    fi

    # Strip any extra trailing slashes ('/') from path if they exist
    # since we are doing an exact string match on the path
    echo "$(echo "${mount_point}" | sed s#//*#/#g)"
}

mountPoints() {
    local mount_point="$(mountPoint "${1}")"
    echo "$(sudo grep "${mount_point}" /proc/mounts | cut -f2 -d" " | sort -r | grep "^${mount_point}")"
}

# ${1} = full path to mountpoint;
# ${2} = if set will not umount; only kill processes in mount
umount_kill() {
    if [ "${VERBOSE}" -le 2 ]; then
        # If enabled, turn off xtrace and remember its current setting.
        if test -o xtrace ; then
            true "$FUNCNAME: Disabling xtrace, because variable VERBOSE (${VERBOSE}) is lower than or equal 2..."
            set +x
            XTRACE_WAS_SET=true
        fi
    fi

    local mount_point="$(mountPoint "${1}")"
    local kill_only="${2}"
    declare -A cache

    # Sync the disk before un-mounting to be sure everything is written
    sync

    output "${red}Attempting to kill any processes still running in '${mount_point}' before un-mounting${reset}"
    mounts="$(mountPoints "${mount_point}")"
    for dir in ${mounts[@]}
    do
        # Escape filename (convert spaces to '\ ', etc
        dir="$(printf "${dir}")"

        # Skip if already in cache
        [[ ${cache["${dir}"]+_} ]] && continue || cache["${dir}"]=1

        # Kill of any processes within mountpoint
        sudo lsof "${dir}" 2> /dev/null | \
            grep "${dir}" | \
            tail -n +2 | \
            awk '{print $2}' | \
            xargs --no-run-if-empty sudo kill -9

        # Umount
        if ! [ "${kill_only}" ]; then

            # Mount point found in mtab
            if $(sudo /usr/bin/mountpoint -q "${dir}"); then
                info "umount ${dir}"
                sudo umount -n "${dir}" 2> /dev/null || \
                    sudo umount -n -l "${dir}" 2> /dev/null || \
                    error "umount ${dir} unsuccessful!"

            # Umount entries not found within '/usr/bin/mountpoint'
            else
                # Look for (deleted) mountpoints
                info "not a regular mount point: ${dir}"
                base="$(basename "${dir}")"
                dir="$(dirname "${dir}")"
                base="$(echo "${base}" | sed 's/[\].*$//')"
                dir="${dir}/${base}"
                sudo umount -v -f -n "${dir}" 2> /dev/null || \
                    sudo umount -v -f -n -l "${dir}" 2> /dev/null || \
                    error "umount ${dir} unsuccessful!"
            fi
        fi
    done

    if [ "$XTRACE_WAS_SET" == "true" ] ; then
       set -x
       true "$FUNCNAME: Restoring xtrace..."
    fi
}

kill_processes_in_mount() {
    umount_kill ${1} "false" || :
}

if [ $(basename "${0}") == "umount_kill.sh" -a "${1}" ]; then
    umount_kill "${1}"
fi
