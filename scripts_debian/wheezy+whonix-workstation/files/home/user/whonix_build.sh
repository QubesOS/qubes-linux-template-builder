################################################################################
# Pre Fixups
sudo mkdir -p /boot/grub2
sudo touch /boot/grub2/grub.cfg
sudo mkdir -p /boot/grub
sudo touch /boot/grub/grub.cfg
sudo mkdir --parents --mode=g+rw "/tmp/uwt"

# Whonix seems to re-install sysvinit even though there is a hold
# on the package.  Things seem to work anyway. BUT hopfully the
# hold on grub* don't get removed
sudo apt-mark hold sysvinit
sudo apt-mark hold grub-pc grub-pc-bin grub-common grub2-common

# Whonix expects haveged to be started
sudo /etc/init.d/haveged start

# ------------------------------------------------------------------------------
# Link our build steps into Whonix build directory
# ------------------------------------------------------------------------------
#pushd /home/user/Whonix/build-steps.d
#cp -pf /home/user/build-steps.d/* .
#popd

# ------------------------------------------------------------------------------
# Whonix installation
# ------------------------------------------------------------------------------
export WHONIX_BUILD_UNATTENDED_PKG_INSTALL="1"

pushd ~/Whonix
sudo ~/Whonix/whonix_build \
    --build $1 \
    --64bit-linux \
    --current-sources \
    --enable-whonix-apt-repository \
    --whonix-apt-repository-distribution $2 \
    --install-to-root \
    --skip-verifiable \
    --minimal-report \
    --skip-sanity-tests || { exit 1; }
popd
