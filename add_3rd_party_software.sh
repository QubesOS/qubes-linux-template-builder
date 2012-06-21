#!/bin/sh

INSTALLDIR=$PWD/mnt

rpm -i --root=$INSTALLDIR 3rd_party_software/adobe-release-x86_64-*.noarch.rpm
rpm --import --root=$INSTALLDIR mnt/etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux
yum install -c $PWD/yum.conf -y --installroot=$INSTALLDIR flash-plugin
