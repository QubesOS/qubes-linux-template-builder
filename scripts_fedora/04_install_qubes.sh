#!/bin/sh
echo "--> Preparing environment..."
mount -t proc proc $PWD/mnt/proc

if [ "$TEMPLATE_FLAVOR" == "minimal" ]; then
    YUM_OPTS="$YUM_OPTS --group_package_types=mandatory"
fi

echo "--> Installing RPMs..."
export YUM0=$PWD/yum_repo_qubes
yum install -c $PWD/yum.conf $YUM_OPTS -y --installroot=$(pwd)/mnt @qubes-vm || RETCODE=1

rpm --root=$PWD/mnt --import $PWD/mnt/etc/pki/rpm-gpg/RPM-GPG-KEY-qubes-*

if [ "$TEMPLATE_FLAVOR" != "minimal" ]; then
    echo "--> Installing 3rd party apps"
    $SCRIPTSDIR/add_3rd_party_software.sh || RETCODE=1
fi

umount $PWD/mnt/proc

exit $RETCODE
