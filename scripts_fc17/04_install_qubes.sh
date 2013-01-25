#!/bin/sh
echo "--> Preparing environment..."
mount -t proc proc $PWD/proc

echo "--> Installing RPMs..."
export YUM0=$PWD/yum_repo_qubes
yum install -c $PWD/yum.conf $YUM_OPTS -y --installroot=$(pwd)/mnt @qubes-vm

echo "--> Installing 3rd party apps"
./add_3rd_party_software.sh

sudo umount $PWD/proc
