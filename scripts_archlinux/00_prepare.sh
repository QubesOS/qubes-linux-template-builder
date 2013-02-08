#!/bin/sh
ISO_VERSION=2013.02.01


echo "Downloading Archlinux dvd..."
wget -O "archlinux-$ISO_VERSION-dual.iso" "http://mir.archlinux.fr/iso/$ISO_VERSION/archlinux-$ISO_VERSION-dual.iso" --continue

echo "Verifying dvd..."
echo "If verification fails, ensure that you imported and verified the archlinux key"
echo "eg: gpg --recv-keys 9741E8AC"

gpg --verify "./scripts_archlinux/archlinux-$ISO_VERSION-dual.iso.sig" "archlinux-$ISO_VERSION-dual.iso" || exit

echo "Extracting squash filesystem from DVD..."
mkdir archlinux_dvd
sudo mount -o loop "archlinux-$ISO_VERSION-dual.iso" archlinux_dvd
cp archlinux_dvd/arch/x86_64/root-image.fs.sfs .
sudo umount archlinux_dvd
sudo mount -o loop root-image.fs.sfs archlinux_dvd
cp archlinux_dvd/root-image.fs .
sudo umount archlinux_dvd
rm root-image.fs.sfs
