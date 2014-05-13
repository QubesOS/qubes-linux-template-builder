#!/bin/sh
if [ -n "${TEMPLATE_FLAVOR}" ]; then
	PKGLISTFILE="$SCRIPTSDIR/packages_${DIST}_${TEMPLATE_FLAVOR}.list"
		if ! [ -r "${PKGLISTFILE}" ]; then
		echo "ERROR: ${PKGLISTFILE} does not exists!"
		exit 1
	fi
elif [ -r "$SCRIPTSDIR/packages_${DIST}.list" ]; then
	PKGLISTFILE="$SCRIPTSDIR/packages_${DIST}.list"
else
	PKGLISTFILE="$SCRIPTSDIR/packages.list"
fi

echo "--> Preparing environment..."
mount -t proc proc mnt/proc

export PKGGROUPS=$(cat $PKGLISTFILE)

export YUM0=$PWD/yum_repo_qubes
yum clean all -c $PWD/yum.conf $YUM_OPTS -y --installroot=$INSTALLDIR
yum install -c $PWD/yum.conf $YUM_OPTS -y --installroot=$INSTALLDIR $PKGGROUPS || RETCODE=1
yum update -c $PWD/yum.conf $YUM_OPTS -y --installroot=$INSTALLDIR || RETCODE=1

umount mnt/proc

exit $RETCODE
