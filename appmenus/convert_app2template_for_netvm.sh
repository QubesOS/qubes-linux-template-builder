#!/bin/sh
SRC=$1
DSTDIR=$2
DST=$DSTDIR/$(basename $SRC)

sed -e "s/^\(Name.*\)=\(.*\)/\1=%VMNAME%: \2/" \
    -e "s/^\(GenericName.*\)=\(.*\)/\1=%VMNAME%: \2/" \
    -e "s/^Exec=\(.*\)/Exec=qvm-run -q --tray -a --user=root %VMNAME% \"\1\"/" \
        <$SRC | \
        grep -v "^Mime" | \
        grep -v "^TryExec" | \
        grep -v "^Startup" >$DST

#echo "Categories=%VMNAME%" >> $DST

echo X-Qubes-VmName=%VMNAME% >> $DST
echo Icon=%VMDIR%/icon.png >> $DST
