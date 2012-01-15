#!/bin/bash

SRC_ROOT=../..
[ -n "$1" ] && SRC_ROOT=$1

: DIST=fc14

rm -fr rpms_to_install/*
VERSION_CORE=$(cat version_core | sed "s/%DIST%/$DIST/")
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-$VERSION_CORE.rpm rpms_to_install/qubes-core-vm
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-libs-$VERSION_CORE.rpm rpms_to_install/qubes-core-vm-libs
if [ "${DIST/fc/}" -ge 15 ]; then
    ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-systemd-$VERSION_CORE.rpm rpms_to_install/qubes-core-vm-init
else
    ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-vm-sysvinit-$VERSION_CORE.rpm rpms_to_install/qubes-core-vm-init
fi

VERSION_GUI=$(cat version_gui | sed "s/%DIST%/$DIST/")
ln -s $SRC_ROOT/gui/rpm/x86_64/qubes-gui-vm-$VERSION_GUI.rpm rpms_to_install/qubes-gui-vm

VERSION_XEN=$(cat version_xen)
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-libs-$VERSION_XEN.rpm rpms_to_install/xen-libs
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-licenses-$VERSION_XEN.rpm rpms_to_install/xen-licenses
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-qubes-vm-essentials-$VERSION_XEN.rpm rpms_to_install/xen-qubes-vm-essentials

# Install also addons
VERSION_TB=$(cat version_addon_tb | sed "s/%DIST%/$DIST/")
ln -s $SRC_ROOT/addons/rpm/x86_64/thunderbird-qubes-$VERSION_TB.rpm rpms_to_install/thunderbird-qubes
VERSION_GPG=$(cat version_addon_gpg | sed "s/%DIST%/$DIST/")
ln -s $SRC_ROOT/addons/rpm/x86_64/qubes-gpg-split-$VERSION_GPG.rpm rpms_to_install/qubes-gpg-split
