#
# This SPEC is for bulding RPM packages that contain complete Qubes Template files
# This includes the VM's root image, patched with all qubes rpms, etc
#

%{!?version: %define version %(cat version)}
%{!?rel: %define rel %(cat build_timestamp_%{DIST})}

Name:		qubes-template-%{template_name}
Version:	%{version}
Release:	%{rel}
Summary:	Qubes template for %{template_name}

License:	GPL
URL:		http://www.qubes-os.org
Source:		.

Requires:	qubes-core-dom0 >= 1.4.1
Requires:	kernel-qubes-vm
Requires:	xdg-utils
Requires(post):	tar
Requires(post):	qubes-core-dom0
Requires(post):	qubes-core-dom0-linux
Provides:	qubes-template
Obsoletes:  %{name} > %{version}-%{release}

%define _builddir %(pwd)
%define _rpmdir %(pwd)/rpm
%define dest_dir /var/lib/qubes/vm-templates/%{template_name}

%define _binaries_in_noarch_packages_terminate_build 0
%description
Qubes template for %{template_name}

%build
cd qubeized_images
rm -f root.img.part.*
tar --sparse -cf - %{template_name}-root.img | split -d -b 1G - root.img.part.
cd ..


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{dest_dir}
for i in qubeized_images/root.img.part.* ; do ln $i $RPM_BUILD_ROOT/%{dest_dir}/`basename $i` ; done
touch $RPM_BUILD_ROOT/%{dest_dir}/root.img # we will create the real file in %post
touch $RPM_BUILD_ROOT/%{dest_dir}/private.img # we will create the real file in %post
touch $RPM_BUILD_ROOT/%{dest_dir}/volatile.img # we will create the real file in %post

cp $SCRIPTSDIR/clean-volatile.img.tar $RPM_BUILD_ROOT/%{dest_dir}/clean-volatile.img.tar

mkdir -p $RPM_BUILD_ROOT/%{dest_dir}/apps.templates
mkdir -p $RPM_BUILD_ROOT/%{dest_dir}/apps
cp -r qubeized_images/%{template_name}-apps.templates/* $RPM_BUILD_ROOT/%{dest_dir}/apps.templates
cp appmenus/whitelisted-appmenus.list appmenus/vm-whitelisted-appmenus.list $RPM_BUILD_ROOT/%{dest_dir}/
cp appmenus/netvm-whitelisted-appmenus.list $RPM_BUILD_ROOT/%{dest_dir}/
touch $RPM_BUILD_ROOT/%{dest_dir}/icon.png

%pre

export XDG_DATA_DIRS=/usr/share/
if [ "$1" -gt 1 ] ; then
    # upgrading already installed template...
    echo "--> Removing previous menu shortcuts..."
    xdg-desktop-menu uninstall --mode system %{dest_dir}/apps/*.directory %{dest_dir}/apps/*.desktop
fi


%post
echo "--> Processing the root.img... (this might take a while)"
cat %{dest_dir}/root.img.part.* | tar --sparse -xf - -C %{dest_dir}
rm -f %{dest_dir}/root.img.part.*
mv %{dest_dir}/%{template_name}-root.img %{dest_dir}/root.img
chown root.qubes %{dest_dir}/root.img
chmod 0660 %{dest_dir}/root.img

echo "--> Processing the volatile.img..."
tar --sparse -xf %{dest_dir}/clean-volatile.img.tar -C %{dest_dir}
chown root.qubes %{dest_dir}/volatile.img
chmod 0660 %{dest_dir}/volatile.img

if [ "$1" = 1 ] ; then
    # installing for the first time
    echo "--> Creating private.img..."
    truncate -s 2G %{dest_dir}/private.img
    mkfs.ext4 -q -F %{dest_dir}/private.img
    chown root.qubes %{dest_dir}/private.img
    chmod 0660 %{dest_dir}/private.img
fi


export XDG_DATA_DIRS=/usr/share/

echo "--> Instaling menu shortcuts..."
ln -sf /usr/share/qubes/icons/template.png %{dest_dir}/icon.png
/usr/libexec/qubes-appmenus/create-apps-for-appvm.sh %{dest_dir}/apps.templates %{template_name} vm-templates

if [ "$1" = 1 ] ; then
    # installing for the first time
    qvm-add-template --rpm %{template_name}
fi

# If running inside of chroot (means - from anaconda), force offline mode
if [ "`stat -c %d:%i /`" != "`stat -c %d:%i /proc/1/root/.`" ]; then
    qvm-template-commit --offline-mode %{template_name}
else
    qvm-template-commit %{template_name}
fi

%preun
if [ "$1" = 0 ] ; then
    # no more packages left
    # First remove DispVM template (even if not exists...)
    qvm-remove --force-root -q %{template_name}-dvm

    if ! qvm-remove --force-root -q --just-db %{template_name}; then
        exit 1
    fi

    rm -f %{dest_dir}/root-cow.img
    rm -f %{dest_dir}/root-cow.img.old
    rm -f %{dest_dir}/firewall.xml
    rm -f %{dest_dir}/%{template_name}.conf
    rm -f %{dest_dir}/updates.stat

    # we need to have it here, because rpm -U <template>
    # apparently executes %preun of the old package *after* %post of the new packages...
    echo "--> Removing menu shortcuts..."
    export XDG_DATA_DIRS=/usr/share/
    xdg-desktop-menu uninstall --mode system %{dest_dir}/apps/*.directory %{dest_dir}/apps/*.desktop

    rm -rf %{dest_dir}/apps %{dest_dir}/apps.templates
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(660,root,qubes,770)
%attr(2770,root,qubes) %dir %{dest_dir}
%ghost %{dest_dir}/root.img
%{dest_dir}/root.img.part.*
%{dest_dir}/clean-volatile.img.tar
%ghost %{dest_dir}/volatile.img
%ghost %{dest_dir}/private.img
%attr (775,root,qubes) %dir %{dest_dir}/apps
%attr (775,root,qubes) %dir %{dest_dir}/apps.templates
%attr (664,root,qubes) %{dest_dir}/apps.templates/*
%attr (664,root,qubes) %{dest_dir}/whitelisted-appmenus.list
%attr (664,root,qubes) %{dest_dir}/vm-whitelisted-appmenus.list
%attr (664,root,qubes) %{dest_dir}/netvm-whitelisted-appmenus.list
%{dest_dir}/icon.png
