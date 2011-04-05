#
# This SPEC is for bulding RPM packages that contain complete Qubes Template files
# This includes the VM's root image, patched with all qubes rpms, etc
#

%{!?version: %define version %(cat version_appvm)}

Name:		qubes-template-%{template_name}
Version:	%{version}
Release:	1
Summary:	Qubes template for %{template_name}

License:	GPL
URL:		http://www.qubes-os.org
Source:		.

Requires:	qubes-core-dom0 >= 1.4.1
Requires:	xdg-utils

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
./create_apps_for_templatevm.sh template/apps.templates/ %{template_name} %{dest_dir} qubeized_images/%{template_name}-apps


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{dest_dir}
for i in qubeized_images/root.img.part.* ; do ln $i $RPM_BUILD_ROOT/%{dest_dir}/`basename $i` ; done
touch $RPM_BUILD_ROOT/%{dest_dir}/root.img # we will create the real file in %post
touch $RPM_BUILD_ROOT/%{dest_dir}/private.img # we will create the real file in %post

cp clean_images/clean-volatile.img.tar $RPM_BUILD_ROOT/%{dest_dir}/clean-volatile.img.tar

cp vm_conf_files/appvm-template.conf $RPM_BUILD_ROOT/%{dest_dir}/appvm-template.conf
cp vm_conf_files/standalone-template.conf $RPM_BUILD_ROOT/%{dest_dir}/standalone-template.conf
cp vm_conf_files/netvm-template.conf $RPM_BUILD_ROOT/%{dest_dir}/netvm-template.conf
cp vm_conf_files/templatevm.conf $RPM_BUILD_ROOT/%{dest_dir}/templatevm.conf
sed -e s/%TEMPLATENAME%/%{template_name}/g < vm_conf_files/templatevm.conf >\
     $RPM_BUILD_ROOT/%{dest_dir}/%{template_name}.conf

cp vm_conf_files/dispvm-prerun.sh $RPM_BUILD_ROOT/%{dest_dir}/

mkdir -p $RPM_BUILD_ROOT/%{dest_dir}/kernels
cp vm_kernels/vmlinuz $RPM_BUILD_ROOT/%{dest_dir}/kernels/vmlinuz
cp vm_kernels/initramfs $RPM_BUILD_ROOT/%{dest_dir}/kernels/initramfs

cp vm_initramfs_patches/qubes_cow_setup.sh $RPM_BUILD_ROOT/%{dest_dir}/kernels/qubes_cow_setup.sh

mkdir -p $RPM_BUILD_ROOT/%{dest_dir}/apps.templates
mkdir -p $RPM_BUILD_ROOT/%{dest_dir}/apps
cp -r qubeized_images/%{template_name}-apps.templates/* $RPM_BUILD_ROOT/%{dest_dir}/apps.templates
cp -r qubeized_images/%{template_name}-apps/* $RPM_BUILD_ROOT/%{dest_dir}/apps
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
xdg-desktop-menu install --mode system %{dest_dir}/apps/*.directory %{dest_dir}/apps/*.desktop

if [ "$1" = 1 ] ; then
    # installing for the first time
    qvm-add-template --rpm %{template_name}
fi

echo "--> Recreating VM conf files..."
/usr/lib/qubes/reset_vm_configs.py %{template_name}

qvm-template-commit %{template_name}

%preun
if [ "$1" = 0 ] ; then
    # no more packages left
    # First remove DispVM template (even if not exists...)
    qvm-remove -q %{template_name}-dvm

    if ! qvm-remove -q --just-db %{template_name}; then
        exit 1
    fi

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
%{dest_dir}/root.img.part.*
%{dest_dir}/clean-volatile.img.tar
%ghost %{dest_dir}/volatile.img
%ghost %{dest_dir}/private.img
%{dest_dir}/appvm-template.conf
%{dest_dir}/netvm-template.conf
%{dest_dir}/standalone-template.conf
%{dest_dir}/templatevm.conf
%{dest_dir}/%{template_name}.conf
%{dest_dir}/dispvm-prerun.sh
%dir %{dest_dir}/kernels
%{dest_dir}/kernels/vmlinuz
%{dest_dir}/kernels/initramfs
%{dest_dir}/kernels/qubes_cow_setup.sh
%attr (775,root,qubes) %dir %{dest_dir}/apps
%attr (664,root,qubes) %{dest_dir}/apps/*
%attr (775,root,qubes) %dir %{dest_dir}/apps.templates
%attr (664,root,qubes) %{dest_dir}/apps.templates/*
%{dest_dir}/icon.png
