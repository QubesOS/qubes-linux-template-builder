#
# This SPEC is for bulding RPM packages that contain complete Qubes NetVM files
# This includes the VM's root image, patched with all qubes rpms, etc
#

%{!?version: %define version %(cat version_netvm)}

%define _binaries_in_noarch_packages_terminate_build 0

Name:		qubes-servicevm-%{netvm_name}
Version:	%{version}
Release:	1
Summary:	Qubes NetVM image for '%{netvm_name}'

License:	GPL
URL:		http://www.qubes-os.org
Source:		.

Requires:	qubes-core-dom0 xdg-utils

%define _builddir %(pwd)
%define _rpmdir %(pwd)/rpm
%define dest_dir /var/lib/qubes/servicevms/%{netvm_name}

%description
Qubes NetVM image for '%{netvm_name}'.

%build
cd qubeized_images
rm -f %{netvm_name}-root.img.tar
tar --sparse -cf %{netvm_name}-root.img.tar %{netvm_name}-root.img
cd ..
./create_apps_for_netvm.sh netvm/apps.templates/ %{netvm_name} %{dest_dir} qubeized_images/%{netvm_name}-apps

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{dest_dir}
ln qubeized_images/%{netvm_name}-root.img.tar $RPM_BUILD_ROOT/%{dest_dir}/root.img.tar
touch $RPM_BUILD_ROOT/%{dest_dir}/root.img # we will create the real file in %post

sed -e s/%NETVMNAME%/%{netvm_name}/ < vm_conf_files/netvm.conf >\
     $RPM_BUILD_ROOT/%{dest_dir}/%{netvm_name}.conf

mkdir -p $RPM_BUILD_ROOT/%{dest_dir}/kernels
cp vm_kernels_netvm/vmlinuz $RPM_BUILD_ROOT/%{dest_dir}/kernels/vmlinuz
cp vm_kernels_netvm/initramfs $RPM_BUILD_ROOT/%{dest_dir}/kernels/initramfs

cp vm_initramfs_patches/qubes_cow_setup.sh $RPM_BUILD_ROOT/%{dest_dir}/kernels/qubes_cow_setup.sh

mkdir -p $RPM_BUILD_ROOT/%{dest_dir}/apps
cp -r qubeized_images/%{netvm_name}-apps/* $RPM_BUILD_ROOT/%{dest_dir}/apps
touch $RPM_BUILD_ROOT/%{dest_dir}/icon.png

%post
echo "--> Processing the root.img... (this might take a while)"
tar --sparse -xf %{dest_dir}/root.img.tar -C %{dest_dir}
rm -f %{dest_dir}/root.img.tar
mv %{dest_dir}/%{netvm_name}-root.img %{dest_dir}/root.img
chown root.qubes %{dest_dir}/root.img
chmod 0660 %{dest_dir}/root.img

export XDG_DATA_DIRS=/usr/share/
if [ "$1" -gt 1 ] ; then
    # upgrading already installed template...
    echo "--> Removing previous menu shortcuts..."
    xdg-desktop-menu uninstall --mode system %{dest_dir}/apps/*.directory %{dest_dir}/apps/*.desktop
fi

echo "--> Instaling menu shortcuts..."
ln -sf /usr/share/qubes/icons/netvm.png %{dest_dir}/icon.png
xdg-desktop-menu install --mode system %{dest_dir}/apps/*.directory %{dest_dir}/apps/*.desktop

echo "--> Adding to Qubes DB..."
if [ "$1" = 1 ] ; then
    # installing for the first time
    qvm-add-netvm %{netvm_name}
else
    qvm-remove -q --just-db %{netvm_name}
    qvm-add-netvm %{netvm_name}
fi

%preun
if [ "$1" = 0 ] ; then
    # no more packages left
    qvm-remove -q --just-db %{netvm_name}

    # we need to have it here, because rpm -U <template>
    # apparently executes %preun of the old package *after* %post of the new packages...
    echo "--> Removing menu shortcuts..."
    export XDG_DATA_DIRS=/usr/share/
    xdg-desktop-menu uninstall --mode system %{dest_dir}/apps/*.directory %{dest_dir}/apps/*.desktop

fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(660,root,qubes,770)
%dir %{dest_dir}
%ghost %{dest_dir}/root.img
%{dest_dir}/root.img.tar
%{dest_dir}/%{netvm_name}.conf
%dir %{dest_dir}/kernels
%{dest_dir}/kernels/vmlinuz
%{dest_dir}/kernels/initramfs
%{dest_dir}/kernels/qubes_cow_setup.sh
%attr (775,root,qubes) %dir %{dest_dir}/apps
%attr (664,root,qubes) %{dest_dir}/apps/*
%{dest_dir}/icon.png
