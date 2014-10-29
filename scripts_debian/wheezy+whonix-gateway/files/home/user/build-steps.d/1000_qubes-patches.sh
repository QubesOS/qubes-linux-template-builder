#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

set -x

WHONIX_DIR="$(readlink -m .)"

# --------------------------------------------------------------------------
# Initialize Whonix submodules
# --------------------------------------------------------------------------
pushd "${WHONIX_DIR}"
{
    sudo git submodule update --init --recursive;
}
popd

# --------------------------------------------------------------------------
# Patch Whonix submodules
# --------------------------------------------------------------------------

# Chekout a branch; create a branch first if it does not exist
checkout_branch() {
    branch=$(git symbolic-ref --short -q HEAD)
    if ! [ "${branch}" == "${1}" ]; then
        sudo -u "${user_name}" git checkout "${1}" >/dev/null 2>&1 || \
        { 
	        sudo -u "${user_name}" git branch "${1}"
	        sudo -u "${user_name}" git checkout "${1}"
        }
    fi
}

# sed search and replace. return 0 if replace happened, otherwise 1 
search_replace() {
    local search="${1}"
    local replace="${2}"
    local file="${3}"

    sed -i.bak '/'"${search}"'/,${s//'"${replace}"'/;b};$q1' "${file}"
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
    search_replace "${search1}" "${replace}" control && \
    {
        cd "${WHONIX_DIR}/packages/anon-meta-packages";
        :
        #sudo -E -u "${user_name}" make deb-pkg || :
        #su "${user_name}" -c "dpkg-source --commit" || :
        #git add .
        #su "${user_name}" -c "git commit -am 'removed grub-pc depend'"
    } || :
}
popd

pushd "${WHONIX_DIR}/packages/anon-shared-build-fix-grub/usr/lib/anon-dist/chroot-scripts-post.d"
{
    search1="update-grub";
    replace=":";

    #checkout_branch qubes
    search_replace "${search1}" "${replace}" 85_update_grub && \
    {
        cd "${WHONIX_DIR}/packages/anon-shared-build-fix-grub";
        sudo -E -u "${user_name}" make deb-pkg || :
        su "${user_name}" -c "EDITOR=/bin/true dpkg-source -q --commit . no_grub";
        #git add . ;
        #su "${user_name}" -c "git commit -am 'removed grub-pc depend'"
    } || :
}
popd

pushd "${WHONIX_DIR}/build-steps.d"
{
    search1="   check_for_uncommited_changes";
    replace="   #check_for_uncommited_changes";

    search_replace "${search1}" "${replace}" 1200_create-debian-packages || :
    }
popd

