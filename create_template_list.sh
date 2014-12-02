#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

#
# Creates a small script to copy to dom0 to retrieve the generated template rpm's
#

template_dir="$(readlink -m ./rpm/install-templates.sh)"
files=( $(ls rpm/noarch) )
name=$(xenstore-read name)

# -----------------------------------------------------------------------------
# Write $vars
# -----------------------------------------------------------------------------
cat << EOF > "${template_dir}"
#!/bin/bash

# Use the following command in DOM0 to retreive this file:
# qvm-run --pass-io ${name} 'cat ${template_dir}' > install-templates.sh

files="
$(printf "%s \n" ${files[@]})
"

path="$(readlink -m .)/rpm/noarch"
version="-$(cat ./version)"
name="${name}"
EOF

# -----------------------------------------------------------------------------
# Write installation function
# -----------------------------------------------------------------------------
cat << 'EOF' >> "${template_dir}"

for file in ${files[@]}; do
    if [ ! -e ${file} ]; then
        echo "Copying ${file} from ${name} to ${PWD}/${file}..."
        qvm-run --pass-io ${name} "cat ${path}/${file}" > ${file}
    fi

    sudo yum erase $(echo "${file}" | sed -r "s/(${version}).+$//") && {
        sudo yum install ${file} && {
            rm -f ${file}
        }
    }
done
EOF
 
# -----------------------------------------------------------------------------
# Display instructions
# -----------------------------------------------------------------------------
echo "Use the following command in DOM0 to retreive this file:"
echo "qvm-run --pass-io ${name} 'cat ${template_dir}' > install-templates.sh"


