#!/bin/bash

cd /tmp
mkdir build
cd build

wget "https://aur.archlinux.org/packages/qu/$1/$1.tar.gz" || exit

gpg --verify "/etc/package.sig" "$1.tar.gz" || exit

tar xzvf $1.tar.gz || exit
cd "$1" || exit

packages=`cat ./PKGBUILD | grep makedepends | cut -d '(' -f 2 | cut -d ')' -f 1`
for package in $packages ; do
 pacman -S --asdeps --noconfirm --needed $package
done
packages=`cat ./PKGBUILD | grep depends | cut -d '(' -f 2 | cut -d ')' -f 1`
for package in $packages ; do
 pacman -S --asdeps --noconfirm --needed $package
done

makepkg --asroot || exit

pacman --noconfirm -U $1-*.pkg.tar.xz || exit


