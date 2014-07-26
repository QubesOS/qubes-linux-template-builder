# The codename of the debian version to install.
# jessie = testing, wheezy = stable
DEBIANVERSION=$DIST

EXTRAPKGS="openssh-clients,screen,vim-nox,less"

QUBESDEBIANGIT="http://dsg.is/qubes/"

# make runs the scripts with sudo -E, so HOME is set to /home/user during
# build, which does not exist. We need to write to $HOME/.gnupg so set it
# to something valid.
HOME=/root

