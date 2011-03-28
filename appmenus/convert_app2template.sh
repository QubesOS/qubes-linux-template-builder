#!/bin/sh
SRC=$1
DSTDIR=$2
DST=$DSTDIR/$(basename $SRC)

if ! grep -q ^Name $SRC ; then
    echo "WARNING: app $SRC doesn't have Name keyword, skipping..."
    exit 0
fi

# Skip all the appmenus not explicitly white-listed
DESKTOP_NAME=$(basename $SRC)
if ! grep -q ^$DESKTOP_NAME$ appmenus/whitelisted-appmenus.list ; then
    exit 0
fi

sed -e "s/^\(Name.*\)=\(.*\)/\1=%VMNAME%: \2/" \
    -e "s/^\(GenericName.*\)=\(.*\)/\1=%VMNAME%: \2/" \
    -e "s/^Exec=\(.*\)/Exec=qvm-run -q --tray -a %VMNAME% \'\1\'/" \
        <$SRC | \
        grep -v "^Mime" | \
        grep -v "^Icon" | \
        grep -v "^TryExec" | \
        grep -v "^OnlyShowIn" | \
        grep -v "^Startup" >$DST

echo X-Qubes-VmName=%VMNAME% >> $DST
echo Icon=%VMDIR%/icon.png >> $DST
