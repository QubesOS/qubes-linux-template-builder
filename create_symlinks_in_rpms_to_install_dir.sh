#!/bin/bash

rm -fr rpms_to_install/*
VERSION_CORE=$(cat version_core)
ln -s ../../core/rpm/x86_64/qubes-core-appvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-appvm
ln -s ../../core/rpm/x86_64/qubes-core-appvm-libs-$VERSION_CORE.rpm rpms_to_install/qubes-core-appvm-libs
ln -s ../../core/rpm/x86_64/qubes-core-commonvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-commonvm
ln -s ../../core/rpm/x86_64/qubes-core-netvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-netvm
ln -s ../../core/rpm/x86_64/qubes-core-proxyvm-$VERSION_CORE.rpm rpms_to_install/qubes-core-proxyvm

VERSION_GUI=$(cat version_gui)
ln -s ../../gui/rpm/x86_64/qubes-gui-vm-$VERSION_GUI.rpm rpms_to_install/qubes-gui-vm

VERSION_XEN=$(cat version_xen)
ln -s ../../xen/rpm/x86_64/xen-libs-$VERSION_XEN.rpm rpms_to_install/xen-libs
ln -s ../../xen/rpm/x86_64/xen-licenses-$VERSION_XEN.rpm rpms_to_install/xen-licenses
ln -s ../../xen/rpm/x86_64/xen-qubes-vm-essentials-$VERSION_XEN.rpm rpms_to_install/xen-qubes-vm-essentials
