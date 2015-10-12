#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

#
# Creates a small script to copy to dom0 to retrieve the generated template rpm's
#

set -e

template_dir="$(readlink -m ./rpm/install-templates.sh)"
path="$(readlink -m .)/rpm/noarch"
version="-$(cat ./version)"
name="$(xenstore-read name)"

files_list_temp="$(echo "rpm/noarch/"*)"
files_list_temp="$(printf "%s \n" ${files_list_temp[@]})"
## Newest versions first.
files_list_temp="$(echo "$files_list_temp" | sort --reverse)"

for file_name in $files_list_temp ; do
   file_name_without_version="$(echo "${file_name}" | sed -r "s/(${version}).+$//")"
   template_name="$(basename "$file_name_without_version")"
   template_list+="$template_name "
done

template_list="$(printf "%s \n" ${template_list[@]})"
template_list="$(echo "$template_list" | sort --unique)"
echo "template_list: $template_list"

declare -A -g remembered

for template_item_from_template_list in $template_list ; do
   for file_name in $files_list_temp ; do
      file_name_without_version="$(echo "${file_name}" | sed -r "s/(${version}).+$//")"
      template_name="$(basename "$file_name_without_version")"
      file_name_basename="$(basename "$file_name")"
      if [ ! "$template_item_from_template_list" = "$template_name" ]; then
         continue
      fi
      if [ "${remembered["$template_name"]}" = "true" ]; then
         files+="#$file_name_basename "
      else
         remembered["$template_name"]="true"
         files+="$file_name_basename "
      fi
   done
done

files="
$(printf "%s \n" ${files[@]})
"

# -----------------------------------------------------------------------------
# Write $vars
# -----------------------------------------------------------------------------
cat << EOF > "${template_dir}"
#!/bin/bash

# Use the following command in DOM0 to retreive this file:
# qvm-run --pass-io ${name} 'cat ${template_dir}' > install-templates.sh

files="${files}"

path="${path}"
version="${version}"
name="${name}"
EOF

# -----------------------------------------------------------------------------
# Write installation function
# -----------------------------------------------------------------------------
cat << 'EOF' >> "${template_dir}"

for file_name in ${files[@]}; do
    if echo "$file_name" | grep -q '^#' ; then
       continue
    fi

    if [ ! -e "${file_name}" ]; then
        echo "Copying ${file_name} from ${name} to ${PWD}/${file_name}..."
        qvm-run --pass-io "${name}" "cat ${path}/${file_name}" > "${PWD}/${file_name}"
    fi

    package_name="$(echo "${file_name}" | sed -r "s/(${version}).+$//")"

    if sudo yum $YUM_OPTS list installed "$package_name" >/dev/null 2>&1 ; then
        echo "Uninstalling package ${package_name}..."
        sudo yum $YUM_OPTS erase "$package_name"
    fi

    echo "Installing file ${file_name}..."
    if sudo yum $YUM_OPTS install "${file_name}" ; then
        echo "Deleting ${PWD}/${file_name}..."
        rm -f "${file_name}"
    fi
done

echo "Done."
EOF

# -----------------------------------------------------------------------------
# Display instructions
# -----------------------------------------------------------------------------
echo "Use the following command in DOM0 to retreive this file:"
echo "qvm-run --pass-io ${name} 'cat ${template_dir}' > install-templates.sh"
