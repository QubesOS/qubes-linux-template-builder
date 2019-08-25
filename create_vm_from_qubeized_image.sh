#!/bin/sh

IMG_DIR=qubeized_images/$TEMPLATE_NAME
if [ ! -d $IMG_DIR ] ; then
	echo "dir not found: $IMG_DIR"
	exit 1
fi
IMG_FILE=$IMG_DIR/root.img
if [ ! -e $IMG_FILE ] ; then
	echo "file not found: $IMG_FILE"
	exit 1
fi

# TODO env overrides
TPL_VMNAME=$TEMPLATE_NAME-`date +%Y%m%d`
TPL_LABEL=purple

HAVE=`qvm-ls -O NAME | grep "$TPL_VMNAME"`
TPL_SUFF=0
TPL_OVMNAME=$TPL_VMNAME
TPL_VMNAME=`
( echo $TPL_VMNAME
while echo "$HAVE" | grep "^$TPL_VMNAME$" &> /dev/null; do
	let TPL_SUFF=$TPL_SUFF+1
	TPL_VMNAME="$TPL_OVMNAME-$TPL_SUFF"
	echo $TPL_VMNAME
done ) | tail -1
`
#echo TPL_VMNAME: $TPL_VMNAME
echo "--> Creating $TPL_VMNAME ..."
qvm-create --label $TPL_LABEL --class TemplateVM $TPL_VMNAME || exit 1

echo "--> Setting $TPL_VMNAME properties ..."
# TODO proper shell escape protection
cat tplspec.$TEMPLATE_NAME $IMG_DIR/template.cfg | 
grep -E "^(prop|feat) [-a-z_]* [a-z0-9A-Z_()/.]*$" | 
while read t k v ; do 
	echo "SPEC '$t' '$k' '$v'" 
	if [ "x$t" == "xprop" ] ; then
	       qvm-prefs $TPL_VMNAME $k "$v"
	elif [ "x$t" == "xfeat" ] ; then
	       qvm-features $TPL_VMNAME $k "$v"
	else
		echo BAD TAG $t
	fi
done

echo "--> Copying root.img to $TPL_VMNAME:root ..."
qrexec-client-vm $TPL_VMNAME admin.vm.volume.Import+root < $IMG_FILE

exit 0

