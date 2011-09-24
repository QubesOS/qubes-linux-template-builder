#!/bin/bash

SRC_ROOT=../..
[ -n "$1" ] && SRC_ROOT=$1

: DIST=fc14

rm -fr rpms_to_install/*
VERSION_CORE=$(cat version_core | sed "s/DIST/$DIST/")
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-appvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-appvm
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-appvm-libs-$VERSION_CORE.rpm rpms_to_install/qubes-core-appvm-libs
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-commonvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-commonvm
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-netvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-netvm
ln -s $SRC_ROOT/core/rpm/x86_64/qubes-core-proxyvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-proxyvm

VERSION_GUI=$(cat version_gui | sed "s/DIST/$DIST/")
ln -s $SRC_ROOT/gui/rpm/x86_64/qubes-gui-vm-$VERSION_GUI.rpm rpms_to_install/qubes-gui-vm

VERSION_XEN=$(cat version_xen)
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-libs-$VERSION_XEN.rpm rpms_to_install/xen-libs
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-licenses-$VERSION_XEN.rpm rpms_to_install/xen-licenses
ln -s $SRC_ROOT/xen/rpm/x86_64/xen-qubes-vm-essentials-$VERSION_XEN.rpm rpms_to_install/xen-qubes-vm-essentials
