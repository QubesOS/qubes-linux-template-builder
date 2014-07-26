#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

rm -f $INSTALLDIR/var/cache/apt/archives/*

rm -f $INSTALLDIR/etc/apt/sources.list.d/qubes-builder.list
rm -f $INSTALLDIR/etc/apt/trusted.gpg.d/qubes-builder.gpg

rm -rf buildchroot

