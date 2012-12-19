#!/bin/sh
SRC=$1
DSTDIR=$2
DST=$DSTDIR/$(basename $SRC)

if ! grep -q ^Name $SRC ; then
    echo "WARNING: app $SRC doesn't have Name keyword, skipping..."
    exit 0
fi

sed -n -e "s/^\(Name.*\)=\(.*\)/\1=%VMNAME%: \2/p" \
    -e "s/^\(GenericName.*\)=\(.*\)/\1=%VMNAME%: \2/p" \
    -e "s/^Exec=\(.*\)/Exec=qvm-run -q --tray -a %VMNAME% \'\1\'/p" \
    -e "/^Comment.*=/p" \
    -e "/Categories=/p" <$SRC >$DST

echo X-Qubes-VmName=%VMNAME% >> $DST
echo Icon=%VMDIR%/icon.png >> $DST
