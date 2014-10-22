#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

VERBOSE=2
DEBUG=1

pushd ../..
export ROOT_DIR=$(readlink -m .)

# ------------------------------------------------------------------------------
# Source external scripts
# ------------------------------------------------------------------------------
. ./functions.sh
. ./tests/assert/assert.sh

head() {
    echo
    echo
    info "------------------------------------------------------------------------------"
    info "${1%%\\n*}"
    if ! [ "${1%%\\n*}" == "${1#*\\n}" ]; then
        [[ -z $TEST ]] && echo -e "${bold}${green}${1#*\\n}${reset}" || :
    fi
    info "------------------------------------------------------------------------------"
}

info() {
    [[ -z $TEST ]] && echo -e "${bold}${blue}${1}${reset}" || :
}

#debug() {
#    [[ -z $TEST ]] && echo -e "${bold}${red}${1}${reset}" || :
#}

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

# Defaults
export SCRIPTSDIR="tests/template-flavors"
export DIST="wheezy"
export TEMPLATE_FLAVOR="whonix-gateway"

# Should be parses in functions!
export TEMPLATE_FLAVOR_PREFIX=""

# Just use error to show text in red
head "=== Globals ==="
debug 'export SCRIPTSDIR="tests/template-flavors"'
debug 'export DIST="wheezy"'
debug 'export TEMPLATE_FLAVOR="whonix-gateway"'
debug 'export TEMPLATE_FLAVOR_PREFIX=""'

# ------------------------------------------------------------------------------
head " 1. With TEMPLATE_FLAVOR
    \n    export SCRIPTSDIR=tests/template-flavors \
    \n    export DIST=wheezy \
    \n    export TEMPLATE_FLAVOR=whonix-gateway \
    \n    export TEMPLATE_FLAVOR_PREFIX="
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 2. Without TEMPLATE_FLAVOR 
    \n    export TEMPLATE_FLAVOR= "
export TEMPLATE_FLAVOR=""
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 3. Template Options
    \n    DISTS_VM = wheezy+whonix-gateway+gnome \
    \n    DISTS_VM = <DIST>+<TEMPLATE_FLAVOR>+<TEMPLATE_OPTIONS>+<TEMPLATE_OPTIONS> \
    \n    Options get seperated into TEMPLATE_OPTIONS seperated by spaces"
#
export TEMPLATE_FLAVOR="whonix-gateway"
export TEMPLATE_OPTIONS=('gnome' 'kde')
buildStep "$0" "pre"
debug "Not supposed to find wheezy+whonix-gateway+kde"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 4. Template Options with custom prefix
    \n    TEMPLATE_FLAVOR_PREFIX \
    \n    export TEMPLATE_FLAVOR_PREFIX=( \
    \n    'wheezy+whonix-gateway;debian+' \
    \n    'wheezy+whonix-workstation;debian+' \
    \n)"
export TEMPLATE_FLAVOR_PREFIX=( 
    'wheezy+whonix-gateway;debian+'
    'wheezy+whonix-workstation;debian+'
)
buildStep "$0" "pre"
debug "Not supposed to find debian+whonix-gateway+kde"
assertTest "buildStep $0 pre" "tests/template-flavors/debian+whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 5. Template Options with NO prefix
    \n    TEMPLATE_FLAVOR_PREFIX \
    \n    export TEMPLATE_FLAVOR_PREFIX=( \
    \n    'wheezy+whonix-gateway;' \
    \n    'wheezy+whonix-workstation;' \
    \n)"
export TEMPLATE_FLAVOR_PREFIX=( 
    'wheezy+whonix-gateway;'
    'wheezy+whonix-workstation;'
)
buildStep "$0" "pre"
debug "Not supposed to find whonix-gateway+kde"
assertTest "buildStep $0 pre" "tests/template-flavors/whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 6. Custom template directory
    \n    unset TEMPLATE_FLAVOR_PREFIX \
    \n    unset TEMPLATE_OPTIONS \
    \n    TEMPLATE_FLAVOR_DIR=wheezy+whonix-gateway;tests/template-flavors/another_location/whonix-gw"
unset TEMPLATE_FLAVOR_PREFIX
unset TEMPLATE_OPTIONS
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway;tests/template-flavors/another_location/whonix-gw"
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/another_location/whonix-gw/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 7. Custom template directory with space in name
    \n    unset TEMPLATE_FLAVOR_PREFIX \
    \n    unset TEMPLATE_OPTIONS \
    \n    TEMPLATE_FLAVOR_DIR=wheezy+whonix-gateway;tests/template-flavors/another_location/whonix gw"
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway;tests/template-flavors/another_location/whonix gw"
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/another_location/whonix gw/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 8. Custom template directory for options
    \n    unset TEMPLATE_FLAVOR_PREFIX \
    \n    unset TEMPLATE_OPTIONS \
    \n    TEMPLATE_FLAVOR_DIR=wheezy+whonix-gateway+gnome;tests/template-flavors/another_location/whonix_gnome"
unset TEMPLATE_FLAVOR_PREFIX
export TEMPLATE_OPTIONS=('gnome')
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway+gnome;tests/template-flavors/another_location/whonix_gnome"
buildStep "$0" "pre"
assertTest "buildStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/another_location/whonix_gnome/test_pre.sh"
assertEnd

# ------------------------------------------------------------------------------
head " 9. Configuration Files
    \n    Find packages.list for every template available" 
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway;tests/template-flavors/another_location/whonix gw"
getFileLocations filelist 'packages.list'
for file in "${filelist[@]}"; do
    echo "Configuration: ${file}"
done
result="$(echo $(printf "'%s' " "${filelist[@]}"))"
assertTest "echo ${result}" "tests/template-flavors/another_location/whonix gw/packages.list tests/template-flavors/wheezy+whonix-gateway+gnome/packages.list"
assertEnd

# ------------------------------------------------------------------------------
head "10. Configuration Files - No Template
    \n    Find packages.list for every template available" 
TEMPLATE_FLAVOR=
TEMPLATE_FLAVOR_DIR=
getFileLocations filelist 'packages.list'
for file in "${filelist[@]}"; do
    echo "Configuration: ${file}"
done
result="$(echo $(printf "'%s' " "${filelist[@]}"))"
assertTest "echo ${result}" "tests/template-flavors/packages.list"
assertEnd

# ------------------------------------------------------------------------------
head "11. Configuration Files - No Template - with suffix
    \n    Find packages.list for every template available" 
TEMPLATE_FLAVOR=
TEMPLATE_FLAVOR_DIR=
getFileLocations filelist 'packages.list' 'wheezy'
for file in "${filelist[@]}"; do
    echo "Configuration: ${file}"
done
result="$(echo $(printf "'%s' " "${filelist[@]}"))"
assertTest "echo ${result}" "tests/template-flavors/packages_wheezy.list"
assertEnd

# ------------------------------------------------------------------------------
export INSTALLDIR="${SCRIPTSDIR}/test_copy_location"
head "12. Copy files
    \n    Just test copying from here to ${INSTALLDIR}"
TEMPLATE_FLAVOR="whonix-gateway"
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""
rm -rf "$INSTALLDIR"/*
copyTree "files"
ls -l "$INSTALLDIR"
assertTest "ls $INSTALLDIR" "test1\ntest2\ntest3"
assertEnd

# Done
popd
