#!/bin/sh
echo "--> Preparing environment..."
mount -t proc proc mnt/proc

export YUM0=$PWD/yum_repo_qubes
yum clean all -c $PWD/yum.conf $YUM_OPTS -y --installroot=$PWD/mnt
yum install -c $PWD/yum.conf $YUM_OPTS -y --installroot=$INSTALLDIR $PKGGROUPS || RETCODE=1
yum update -c $PWD/yum.conf $YUM_OPTS -y --installroot=$INSTALLDIR || RETCODE=1

umount mnt/proc mnt
