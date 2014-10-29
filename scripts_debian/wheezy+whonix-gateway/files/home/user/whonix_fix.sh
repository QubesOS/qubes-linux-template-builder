DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    sudo apt-get -y --force-yes remove grub-pc grub-common grub-pc-bin grub2-common
    sudo apt-mark hold grub-common grub-pc-bin grub2-common
