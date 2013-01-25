#!/bin/sh

echo "-> Initializing RPM database..."
rpm --initdb --root=$INSTALLDIR
rpm --import --root=$INSTALLDIR keys/*

echo "-> Installing core RPM packages..."
rpm -i --root=$INSTALLDIR base_rpms/*.rpm || exit 1

cp scripts_"${DIST}"/resolv.conf $INSTALLDIR/etc
cp scripts_"${DIST}"/network $INSTALLDIR/etc/sysconfig
cp -a /dev/null /dev/zero /dev/random /dev/urandom $INSTALLDIR/dev/
