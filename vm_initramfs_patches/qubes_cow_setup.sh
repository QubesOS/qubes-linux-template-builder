#
# This file should be places in pre-mount directory in dracut's initramfs
#

#!/bin/sh
echo "Qubes initramfs script here:"

if [ -e /dev/mapper/dmroot ] ; then 
    die "Qubes: FATAL error: /dev/mapper/dmroot already exists?!"
fi

modprobe xenblk || modprobe xen-blkfront || echo "Qubes: Cannot load Xen Block Frontend..."

echo "Waiting for /dev/xvda* devices..."
while ! [ -e /dev/xvda ]; do sleep 0.1; done
while ! [ -e /dev/xvda1 ] ; do sleep 0.1; done
while ! [ -e /dev/xvda2 ] ; do sleep 0.1; done

if [ `blockdev --getro /dev/xvda` = 1 ] ; then
	echo "Qubes: Doing COW setup for AppVM..."

	while ! [ -e /dev/xvdc ]; do sleep 0.1; done
	while ! [ -e /dev/xvdd ]; do sleep 0.1; done

	echo "0 `blockdev --getsz /dev/xvda1` snapshot /dev/xvda1 /dev/xvdc P 16" | \
    		dmsetup create dmroot || { echo "Qubes: FATAL: cannot create dmroot!"; }
	echo "0 `blockdev --getsz /dev/xvda2` snapshot /dev/xvda2 /dev/xvdd P 16" | \
    		dmsetup create dmswap || { echo "Qubes: FATAL: cannot create dmswap!"; }
	echo Qubes: done.
else
	echo "Qubes: Doing R/W setup for TemplateVM..."
	echo "0 `blockdev --getsz /dev/xvda1` linear /dev/xvda1 0" | \
    		dmsetup create dmroot || { echo "Qubes: FATAL: cannot create dmroot!"; exit 1; }
	echo "0 `blockdev --getsz /dev/xvda2` linear /dev/xvda2 0" | \
    		dmsetup create dmswap || { echo "Qubes: FATAL: cannot create dmswap!"; exit 1; }
	echo Qubes: done.
fi
