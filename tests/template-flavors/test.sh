#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

VERBOSE=2
DEBUG=1

pushd ../..
ROOT_DIR=$(readlink -m .)

# ------------------------------------------------------------------------------
# Source external scripts
# ------------------------------------------------------------------------------
. ./functions.sh
. ./tests/assert/assert.sh

header() {
    echo
    echo
    info "------------------------------------------------------------------------------"

    IFS= read -r title; info "${title}"
    while IFS= read -r line; do 
        echo "${bold}${magenta}${line}${reset}"
    done; 

    echo
    values SCRIPTSDIR
    values DIST
    values DISTS_VM
    values TEMPLATE_FLAVOR
    values TEMPLATE_FLAVOR_PREFIX
    values TEMPLATE_FLAVOR_DIR
    values TEMPLATE_OPTIONS
    echo
}

declare -A VALUES=(
    [SCRIPTSDIR]="" 
    [DIST]="" 
    [DISTS_VM]="" 
    [TEMPLATE_FLAVOR]=""
    [TEMPLATE_FLAVOR_DIR]="" 
    [TEMPLATE_FLAVOR_PREFIX]="" 
    [TEMPLATE_OPTIONS]=""
)

values() {
    [[ -z $TEST ]] && {
        label=${1}
        value="${1}[@]"
        value="${!value}"

        if [ "${VALUES[$label]}" == "${value}" ]; then
            printf "    ${bold}${magenta}%-22s = ${value}${reset}\n" "${label}" || :
        else
            printf "    ${bold}${black}%-22s = ${value}${reset}\n" "${label}" || :
        fi
        #printf "${bold}${black}%s=\"${value}\"${reset}\n" "${label}" || :
        VALUES[$label]="${value}"
    }
}

info() {
    [[ -z $TEST ]] && echo "${bold}${blue}${1}${reset}" || :
}

debug() {
    [[ -z $TEST ]] && echo -e "${magenta}${1}${reset}" || :
}

assertTest(){
    TEST=True
    printf "${bold}${red}"
    assert "$1" "$2"
    printf "${reset}"
    unset TEST
}

assertEnd() {
    printf "${bold}${red}"
    [[ -n "$1" ]] && assert_end "$1" || assert_end
    printf "${reset}"
}

# ------------------------------------------------------------------------------
# 1. With TEMPLATE_FLAVOR
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""

header <<EOF
 1. With TEMPLATE_FLAVOR
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 2. Without TEMPLATE_FLAVOR 
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR=""
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""

header <<EOF
 2. Without TEMPLATE_FLAVOR 
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 3. Template Options
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=('gnome' 'kde')

header <<EOF
 3. Template Options
    Options get seperated into TEMPLATE_OPTIONS seperated by spaces
EOF
buildStep "$0" "pre"
debug "Not supposed to find wheezy+whonix-gateway+kde"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 4. Template Options with custom prefix
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=('gnome' 'kde')
TEMPLATE_FLAVOR_PREFIX=( 
    'wheezy+whonix-gateway:debian+'
    'wheezy+whonix-workstation:debian+'
)
header <<EOF
 4. Template Options with custom prefix
EOF
buildStep "$0" "pre"
debug "Not supposed to find debian+whonix-gateway+kde"
assertTest "buildStep $0 pre" "tests/template-flavors/debian+whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 5. Template Options with NO prefix
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=('gnome' 'kde')
TEMPLATE_FLAVOR_PREFIX=( 
    'wheezy+whonix-gateway:'
    'wheezy+whonix-workstation:'
)
header <<EOF
 5. Template Options with NO prefix
EOF
buildStep "$0" "pre"
debug "Not supposed to find whonix-gateway+kde"
assertTest "buildStep $0 pre" "tests/template-flavors/whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 6. Custom template directory for options within \${SCRIPTSDIR}
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway+gnome:${SCRIPTSDIR}/another_location/whonix_gnome"
TEMPLATE_OPTIONS=('gnome')

header <<EOF
 6. Custom template directory for options within \${SCRIPTSDIR}
    NOTE: in config file you would need to use \$\${SCRIPTSDIR} or whatever variable
    and in a bash file use single 'quotes' around string and \${SCRIPTSDIR}
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/another_location/whonix_gnome/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 7. Custom template directory
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway:tests/template-flavors/another_location/whonix-gw"
TEMPLATE_OPTIONS=""

header <<EOF
 7. Custom template directory
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/another_location/whonix-gw/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 8. Custom template directory with space in name
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=("wheezy+whonix-gateway:tests/template-flavors/another_location/whonix gw")
TEMPLATE_OPTIONS=""

header <<EOF
 8. Custom template directory with space in name
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/another_location/whonix gw/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 9. Custom template directory for options
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway+gnome:tests/template-flavors/another_location/whonix_gnome"
TEMPLATE_OPTIONS=('gnome')

header <<EOF
 9. Custom template directory for options
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/another_location/whonix_gnome/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 10. Template directory for options within $SCRIPTSDIR using short name filter
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR="wheezy+proxy:${SCRIPTSDIR}/proxy"
TEMPLATE_OPTIONS=('proxy')

header <<EOF
10. Template directory for options within $SCRIPTSDIR using short name filter
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/proxy/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 11. Template directory for options within using VERY short name filter (+proxy)
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR="+proxy:${SCRIPTSDIR}/proxy"
TEMPLATE_OPTIONS=('proxy')

header <<EOF
11. Template directory for options within using VERY short name filter (+proxy)
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/proxy/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 12. Template Name - Custom
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""
TEMPLATE_LABEL="wheezy+whonix-gateway:whonix-gateway"

header <<EOF
12. Template Name - Custom
    TEMPLATE_LABEL         = wheezy+whonix-gateway:whonix-gateway
EOF
info "Template name: $(templateName)"
assertTest "templateName" "whonix-gateway"
assertEnd


# ------------------------------------------------------------------------------
# 13. Template Name - Custom with sub-options
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=('proxy')
TEMPLATE_LABEL="wheezy+whonix-gateway+proxy:whonix-gateway"

header <<EOF
13. Template Name - Custom with sub-options
    TEMPLATE_LABEL         = wheezy+whonix-gateway+proxy:whonix-gateway
EOF
info "Template name: $(templateName)"
assertTest "templateName" "whonix-gateway"
assertEnd


# ------------------------------------------------------------------------------
# 14. Template Name - NO template
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR=""
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""
TEMPLATE_LABEL="wheezy:debian-7"

header <<EOF
14. Template Name - NO template
    TEMPLATE_LABEL         = wheezy:debian-7
EOF
info "Template name: $(templateName)"
assertTest "templateName" "debian-7"
assertEnd


# ------------------------------------------------------------------------------
# 15. Configuration Files
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=(
    'wheezy+whonix-gateway:tests/template-flavors/another_location/whonix gw' 
    '+gnome:$${SCRIPTSDIR}/gnome'
)
TEMPLATE_OPTIONS=('gnome')

header <<EOF
15. Configuration Files
    Find packages.list for every template available
EOF
getFileLocations filelist 'packages.list'
for file in "${filelist[@]}"; do
    echo "Configuration: ${file}"
done
result="$(echo $(printf "'%s' " "${filelist[@]}"))"
assertTest "echo ${result}" "tests/template-flavors/another_location/whonix gw/packages.list tests/template-flavors/wheezy+whonix-gateway+gnome/packages.list"
assertEnd


# ------------------------------------------------------------------------------
# 16. Configuration Files - No Template
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR=""
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=('gnome')

header <<EOF
16. Configuration Files - No Template
    Find packages.list for every template available
EOF
getFileLocations filelist 'packages.list'
for file in "${filelist[@]}"; do
    echo "Configuration: ${file}"
done
result="$(echo $(printf "'%s' " "${filelist[@]}"))"
assertTest "echo ${result}" "tests/template-flavors/packages.list"
assertEnd


# ------------------------------------------------------------------------------
# 17. Configuration Files - No Template - with suffix
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR=""
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=('gnome')

header <<EOF
17. Configuration Files - No Template - with suffix
     Find packages.list for every template available
EOF
getFileLocations filelist 'packages.list' 'wheezy'
for file in "${filelist[@]}"; do
    echo "Configuration: ${file}"
done
result="$(echo $(printf "'%s' " "${filelist[@]}"))"
assertTest "echo ${result}" "tests/template-flavors/packages_wheezy.list"
assertEnd

# ------------------------------------------------------------------------------
# 18. Copy files
# ------------------------------------------------------------------------------
SCRIPTSDIR="tests/template-flavors"
DIST="wheezy"
DISTS_VM=""
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""
INSTALLDIR="${SCRIPTSDIR}/test_copy_location"

header <<EOF 
18. Copy files
    Just test copying from here to ${INSTALLDIR}
    INSTALLDIR="${SCRIPTSDIR}/test_copy_location"
EOF
rm -f "$INSTALLDIR"/test1
rm -f "$INSTALLDIR"/test2
rm -f "$INSTALLDIR"/test3
copyTree "files"
ls -l "$INSTALLDIR"
assertTest "ls $INSTALLDIR" "test1\ntest2\ntest3"
assertEnd


# Done
popd
