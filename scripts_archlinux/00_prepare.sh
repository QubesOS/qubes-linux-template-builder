#!/bin/sh
ISO_VERSION=2014.07.03

mkdir -p $CACHEDIR

echo "Downloading Archlinux dvd..."
wget -N -P $CACHEDIR "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso"
wget -N -P $CACHEDIR "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso.sig"

echo "Verifying dvd..."
gpg --import "$SCRIPTSDIR/archlinux-master-keys.asc"

gpg --verify "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso.sig" "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" || exit

if [ "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" -nt $CACHEDIR/root-image.fs ]; then
	echo "Extracting squash filesystem from DVD..."
	mkdir mnt_archlinux_dvd
	mount -o loop "$CACHEDIR/archlinux-$ISO_VERSION-dual.iso" mnt_archlinux_dvd
	cp mnt_archlinux_dvd/arch/x86_64/root-image.fs.sfs $CACHEDIR/
	umount mnt_archlinux_dvd
	mount -o loop $CACHEDIR/root-image.fs.sfs mnt_archlinux_dvd
	cp mnt_archlinux_dvd/root-image.fs $CACHEDIR/
	umount mnt_archlinux_dvd
	rm $CACHEDIR/root-image.fs.sfs
fi
