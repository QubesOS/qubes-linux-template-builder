#!/bin/sh

echo "Downloading Archlinux dvd..."
wget -O "archlinux.iso" "http://mir.archlinux.fr/iso/latest/arch/x86_64/root-image.fs.sfs" --continue

echo "Extracting squash filesystem from DVD..."
mkdir archlinux_dvd
sudo mount -o loop archlinux.iso archlinux_dvd
cp archlinux_dvd/root-image.fs .
sudo umount archlinux_dvd
