#!/bin/bash

SRC_ROOT=../..
[ -n "$1" ] && SRC_ROOT=$1

: DIST=fc14

rm -fr rpms_to_install/*
pushd rpms_to_install
# FIXME: rel hardcoded
VERSION_CORE=$(cat $SRC_ROOT/core/version_vm)-1.$DIST.x86_64
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-$VERSION_CORE.rpm qubes-core-vm
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-libs-$VERSION_CORE.rpm qubes-core-vm-libs
if [ "${DIST/fc/}" -ge 15 ]; then
    ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-systemd-$VERSION_CORE.rpm qubes-core-vm-init
else
    ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-sysvinit-$VERSION_CORE.rpm qubes-core-vm-init
fi

# FIXME: rel hardcoded
VERSION_GUI=$(cat $SRC_ROOT/gui/version)-1.$DIST.x86_64
ln -s $SRC_ROOT/gui/rpm/x86_64/qubes-gui-vm-$VERSION_GUI.rpm qubes-gui-vm

VERSION_XEN=$(cat $SRC_ROOT/xen/version)-$(cat $SRC_ROOT/xen/rel).qubes.x86_64
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-libs-$VERSION_XEN.rpm xen-libs
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-licenses-$VERSION_XEN.rpm xen-licenses
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-qubes-vm-essentials-$VERSION_XEN.rpm xen-qubes-vm-essentials

# Install also addons
# FIXME: rel hardcoded
VERSION_TB=$(cat $SRC_ROOT/addons/thunderbird-qubes/version)-1.$DIST.x86_64
ln -s $SRC_ROOT/addons/rpm/x86_64/thunderbird-qubes-$VERSION_TB.rpm thunderbird-qubes
# FIXME: rel hardcoded
VERSION_GPG=$(cat $SRC_ROOT/addons/gpg-split/version)-1.$DIST.x86_64
ln -s $SRC_ROOT/addons/rpm/x86_64/qubes-gpg-split-$VERSION_GPG.rpm qubes-gpg-split

popd
