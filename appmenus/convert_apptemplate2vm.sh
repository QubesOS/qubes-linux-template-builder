#!/bin/sh
SRC=$1
DSTDIR=$2
VMNAME=$3
VMDIR=$4

DST=$DSTDIR/$VMNAME-$(basename $SRC)

sed -e "s/%VMNAME%/$VMNAME/g" \
    -e "s %VMDIR% $VMDIR " \
        <$SRC >$DST


