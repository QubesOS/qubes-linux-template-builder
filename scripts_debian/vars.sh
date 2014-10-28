#!/bin/bash

# ------------------------------------------------------------------------------
# Global variables and functions
# ------------------------------------------------------------------------------

. ./functions.sh

# The codename of the debian version to install.
# jessie = testing, wheezy = stable
DEBIANVERSION=${DIST}

# Location to grab debian packages
#DEBIAN_MIRROR=http://http.debian.net/debian
DEBIAN_MIRROR=http://ftp.ca.debian.org/debian/
#DEBIAN_MIRROR=http://ftp.us.debian.org/debian/

# XXX: Is this even used?
EXTRAPKGS="openssh-clients,screen,vim-nox,less"

# XXX: Is this even used?
QUBESDEBIANGIT="http://dsg.is/qubes/"

# XXX: Is this even used?
# make runs the scripts with sudo -E, so HOME is set to /home/user during
# build, which does not exist. We need to write to ${HOME}/.gnupg so set it
# to something valid.
HOME=/root
