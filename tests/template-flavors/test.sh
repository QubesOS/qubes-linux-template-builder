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
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_PREFIX=""

header <<EOF
 1. With TEMPLATE_FLAVOR
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 2. Without TEMPLATE_FLAVOR 
# ------------------------------------------------------------------------------
TEMPLATE_FLAVOR=""

header <<EOF
 2. Without TEMPLATE_FLAVOR 
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 3. Template Options
# ------------------------------------------------------------------------------
TEMPLATE_FLAVOR="whonix-gateway"
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
unset TEMPLATE_FLAVOR_PREFIX
TEMPLATE_OPTIONS=('gnome')
TEMPLATE_FLAVOR_DIR='wheezy+whonix-gateway+gnome:${SCRIPTSDIR}/another_location/whonix_gnome'

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
unset TEMPLATE_FLAVOR_PREFIX
unset TEMPLATE_OPTIONS
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway:tests/template-flavors/another_location/whonix-gw"

header <<EOF
 7. Custom template directory
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/another_location/whonix-gw/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 8. Custom template directory with space in name
# ------------------------------------------------------------------------------
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway:tests/template-flavors/another_location/whonix gw"

header <<EOF
 8. Custom template directory with space in name
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/another_location/whonix gw/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 9. Custom template directory for options
# ------------------------------------------------------------------------------
unset TEMPLATE_FLAVOR_PREFIX
TEMPLATE_OPTIONS=('gnome')
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway+gnome:tests/template-flavors/another_location/whonix_gnome"

header <<EOF
 9. Custom template directory for options
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/another_location/whonix_gnome/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 10. Template directory for options within $SCRIPTSDIR using short name filter
# ------------------------------------------------------------------------------
unset TEMPLATE_FLAVOR_PREFIX
unset TEMPLATE_FLAVOR_DIR
TEMPLATE_OPTIONS=('proxy')
TEMPLATE_FLAVOR_DIR='wheezy+proxy:${SCRIPTSDIR}/proxy'

header <<EOF
10. Template directory for options within $SCRIPTSDIR using short name filter
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/proxy/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 11. Template directory for options within using VERY short name filter (+proxy)
# ------------------------------------------------------------------------------
unset TEMPLATE_FLAVOR_PREFIX
unset TEMPLATE_FLAVOR_DIR
TEMPLATE_OPTIONS=('proxy')
TEMPLATE_FLAVOR_DIR='+proxy:${SCRIPTSDIR}/proxy'

header <<EOF
11. Template directory for options within using VERY short name filter (+proxy)
EOF
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/proxy/test_pre.sh"
assertEnd


# ------------------------------------------------------------------------------
# 12. Configuration Files
# ------------------------------------------------------------------------------
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway:tests/template-flavors/another_location/whonix gw"
TEMPLATE_OPTIONS=('gnome')

header <<EOF
12. Configuration Files
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
# 13. Configuration Files - No Template
# ------------------------------------------------------------------------------
TEMPLATE_FLAVOR=
TEMPLATE_FLAVOR_DIR=

header <<EOF
13. Configuration Files - No Template
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
# 14. Configuration Files - No Template - with suffix
# ------------------------------------------------------------------------------
TEMPLATE_FLAVOR=
TEMPLATE_FLAVOR_DIR=

header <<EOF
14. Configuration Files - No Template - with suffix
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
# 14. Copy files
# ------------------------------------------------------------------------------
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""
INSTALLDIR="${SCRIPTSDIR}/test_copy_location"

header <<EOF 
14. Copy files
    Just test copying from here to ${INSTALLDIR}
    INSTALLDIR="${SCRIPTSDIR}/test_copy_location"
EOF
rm -rf "$INSTALLDIR"/*
copyTree "files"
ls -l "$INSTALLDIR"
assertTest "ls $INSTALLDIR" "test1\ntest2\ntest3"
assertEnd


# Done
popd
