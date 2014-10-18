#!/bin/bash

#
# Creates a small script to copy to dom0 to retrieve the generated template rpm's
#

TEMPLATES="./rpm/install-templates.sh"

TEMPLATES="$(readlink -m $TEMPLATES)"
touch "$TEMPLATES"
write() {
    echo "$1" >> "$TEMPLATES"
}

write "#!/bin/bash"
write ""

if [ -x /usr/sbin/xenstore-read ]; then
        XENSTORE_READ="/usr/sbin/xenstore-read"
else
        XENSTORE_READ="/usr/bin/xenstore-read"
fi

VERSION="-$(cat ./version)"
name=$($XENSTORE_READ name)
path="$(readlink -m .)"
files=$(ls rpm/noarch)

for file in ${files[@]}; do
    write "qvm-run --pass-io development-qubes 'cat ${path}/rpm/noarch/${file}' > ${file}"
    write ""
    write "yum erase $(echo "$file" | sed -r "s/($VERSION).+$//")"
    write ""
    write "yum install ${file}"
    write ""
    write ""
done

write "# Use the following command in DOM0 to retreive this file:"
write "# qvm-run --pass-io $name 'cat ${TEMPLATES}' > install-templates.sh"

echo "Use the following command in DOM0 to retreive this file:"
echo "qvm-run --pass-io $name 'cat ${TEMPLATES}' > install-templates.sh"


