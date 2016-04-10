#!/bin/sh
ROOTIMG=$1

if [ x$ROOTIMG = x ] ; then
echo "usage: $0 <root.img>"
exit 0
fi

# We assume that the input root.img has the following structure:

# /dev/sda1 <--- root fs
# /dev/sda2 <--- swap

# and that the first partition starts at offset 63*512 from the begging of the image file
OFFSET=$((63*512))

mkdir -p mnt

MNTDIR=$(pwd)/mnt

LOOP=$(/sbin/losetup -f --show -o $OFFSET $ROOTIMG)

if [ x$LOOP = x ] ; then
echo "Cannot setup loopback device for the $ROOTIMG file -- perhaps a permissions problem?"
exit 1
fi

mount $LOOP $MNTDIR || {
echo "Cannot mount $LOOP to $MNTDIR"
/sbin/losetup -d $LOOP
exit 2
}

# generate unmount script
BASENAE=$(basename $ROOTIMG)
UNMOUNT_SCRIPT=$(echo unmount_root-$BASENAE.sh)
echo "#!/bin/sh" > $UNMOUNT_SCRIPT
echo "umount $MNTDIR || { echo \"Cannot unmount!\"; exit 1; }" >> $UNMOUNT_SCRIPT
echo "/sbin/losetup -d $LOOP || { echo \"Cannot delete the loop device\"; exit 1; }" >> $UNMOUNT_SCRIPT
echo "rm -f $UNMOUNT_SCRIPT" >> $UNMOUNT_SCRIPT
chmod +x $UNMOUNT_SCRIPT

