#!/bin/sh

if ! [ -f "${INSTALLDIR}/tmp/.prepared_base" ]; then
    echo "-> Initializing RPM database..."
    rpm --initdb --root=$INSTALLDIR
    rpm --import --root=$INSTALLDIR $SCRIPTSDIR/keys/*

    echo "-> Installing core RPM packages..."
    rpm -i --root=$INSTALLDIR $SCRIPTSDIR/base_rpms/*.rpm || exit 1

    touch "${INSTALLDIR}/tmp/.prepared_base"
fi

cp $SCRIPTSDIR/resolv.conf $INSTALLDIR/etc
cp $SCRIPTSDIR/network $INSTALLDIR/etc/sysconfig
cp -a /dev/null /dev/zero /dev/random /dev/urandom $INSTALLDIR/dev/
