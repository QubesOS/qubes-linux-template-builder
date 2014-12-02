#!/bin/bash

# ------------------------------------------------------------------------------
# Global variables and functions
# ------------------------------------------------------------------------------

. ./functions.sh

# The codename of the debian version to install.
# jessie = testing, wheezy = stable
DEBIANVERSION=${DIST}

# Location to grab debian packages
DEBIAN_MIRROR=http://ftp.us.debian.org/debian
#DEBIAN_MIRROR=http://http.debian.net/debian
#DEBIAN_MIRROR=http://ftp.ca.debian.org/debian

APT_GET_OPTIONS="-o Dpkg::Options::="--force-confnew" --force-yes -y"
