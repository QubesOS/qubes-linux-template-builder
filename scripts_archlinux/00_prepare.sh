#!/bin/sh
ISO_VERSION=2013.02.01

mkdir -p $CACHEDIR

echo "Downloading Archlinux dvd..."
wget -N -P $CACHEDIR "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso"

echo "Verifying dvd..."
echo "If verification fails, ensure that you imported and verified the archlinux key"
echo "eg: gpg --recv-keys 9741E8AC"

gpg --verify "$SCRIPTSDIR/archlinux-$ISO_VERSION-dual.iso.sig" "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" || exit

if [ "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" -nt $CACHEDIR/root-image.fs ]; then
	echo "Extracting squash filesystem from DVD..."
	mkdir mnt_archlinux_dvd
	sudo mount -o loop "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" mnt_archlinux_dvd
	cp mnt_archlinux_dvd/arch/x86_64/root-image.fs.sfs $CACHEDIR/
	sudo umount mnt_archlinux_dvd
	sudo mount -o loop $CACHEDIR/root-image.fs.sfs mnt_archlinux_dvd
	cp mnt_archlinux_dvd/root-image.fs $CACHEDIR/
	sudo umount mnt_archlinux_dvd
	rm $CACHEDIR/root-image.fs.sfs
fi
