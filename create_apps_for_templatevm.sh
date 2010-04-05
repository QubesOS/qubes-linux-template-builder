#!/bin/sh
SRCDIR=$1
VMNAME=$2
VMDIR=$3
APPSDIR=$4

if [ $# != 4 ]; then
    echo "usage: $0 <apps_templates_dir> <vmname> <vmdir> <apps_dir>"
    exit
fi
mkdir -p $APPSDIR

find $SRCDIR -name "*.desktop" -exec appmenus/convert_apptemplate2vm.sh {} $APPSDIR $VMNAME $VMDIR \;

appmenus/convert_dirtemplate2vm.sh appmenus/qubes-templatevm.directory.template $APPSDIR/$VMNAME-vm.directory $VMNAME $VMDIR
