#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

. $SCRIPTSDIR/vars.sh

echo "-> Installing base debian system"

COMPONENTS="" debootstrap --arch=amd64 --include=ncurses-term \
    --components=main --keyring=${SCRIPTSDIR}/debian-archive-keyring.gpg \
    $DEBIANVERSION "$INSTALLDIR" http://http.debian.net/debian || { echo "Debootstrap failed!"; exit 1; }

