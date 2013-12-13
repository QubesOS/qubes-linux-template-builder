#!/bin/sh

INSTALLDIR=$PWD/mnt

rpm -i --root=$INSTALLDIR $SCRIPTSDIR/3rd_party_software/adobe-release-x86_64-*.noarch.rpm || exit 1
rpm --import --root=$INSTALLDIR mnt/etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux
yum install -c $PWD/yum.conf $YUM_OPTS -y --installroot=$INSTALLDIR flash-plugin || exit 1
