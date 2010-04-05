#!/bin/sh
SRC=$1
DSTDIR=$2
DST=$DSTDIR/$(basename $SRC)

# Do not copy KDE/GNOME specific apps, e.g. "Home", "Find files", etc
if grep -q OnlyShowIn $SRC ; then
    exit 0
fi

if ! grep -q ^Name $SRC ; then
    echo "WARNING: app $SRC doesn't have Name keyword, skipping..."
    exit 0
fi

sed -e "s/^\(Name.*\)=\(.*\)/\1=%VMNAME%: \2/" \
    -e "s/^\(GenericName.*\)=\(.*\)/\1=%VMNAME%: \2/" \
    -e "s/^Exec=\(.*\)/Exec=qvm-run -q --tray -a %VMNAME% \'\1\'/" \
        <$SRC | \
        grep -v "^Mime" | \
        grep -v "^Icon" | \
        grep -v "^TryExec" | \
        grep -v "^Startup" >$DST

echo X-Qubes-VmName=%VMNAME% >> $DST
echo Icon=%VMDIR%/icon.png >> $DST
