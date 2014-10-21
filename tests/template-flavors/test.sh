#!/bin/sh
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
    assert_end "$1"
    printf "${reset}"
}

# Defaults
export SCRIPTDIR="tests/template-flavors"
export DIST="wheezy"
export TEMPLATE_FLAVOR="whonix-gateway"

# Should be parses in functions!
export TEMPLATE_FLAVOR_PREFIX=""

# Just use error to show text in red
head "=== Globals ==="
debug 'export SCRIPTDIR="tests/template-flavors"'
debug 'export DIST="wheezy"'
debug 'export TEMPLATE_FLAVOR="whonix-gateway"'
debug 'export TEMPLATE_FLAVOR_PREFIX=""'
#debug "TEST=\"${TEST}\""

# ------------------------------------------------------------------------------
head " 1. With TEMPLATE_FOLDER
    \n    tests/template-flavors/wheezy+whonix-gateway/test_pre.sh"
customStep "$0" "pre"
assertTest "customStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh"
assertEnd "Test 1"

# ------------------------------------------------------------------------------
head " 2. Without TEMPLATE_FOLDER 
    \n    tests/template-flavors/wheezy/test_pre.sh"
export TEMPLATE_FLAVOR=""
customStep "$0" "pre"
assertTest "customStep $0 pre" "tests/template-flavors/wheezy/test_pre.sh"
assertEnd "Test 2"

# ------------------------------------------------------------------------------
head " 3. Template Options
    \n    DISTS_VM = wheezy+whonix-gateway+gnome \
    \n    DISTS_VM = <DIST>+<TEMPLATE_FLAVOR>+<TEMPLATE_OPTIONS>+<TEMPLATE_OPTIONS> \
    \n    Options get seperated into TEMPLATE_OPTIONS seperated by spaces"
#
export TEMPLATE_FLAVOR="whonix-gateway"
export TEMPLATE_OPTIONS=('gnome' 'kde')
customStep "$0" "pre"
debug "Not supposed to find wheezy+whonix-gateway+kde"
assertTest "customStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd "Test 3"

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
customStep "$0" "pre"
debug "Not supposed to find debian+whonix-gateway+kde"
assertTest "customStep $0 pre" "tests/template-flavors/debian+whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd "Test 4"

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
customStep "$0" "pre"
debug "Not supposed to find whonix-gateway+kde"
assertTest "customStep $0 pre" "tests/template-flavors/whonix-gateway/test_pre.sh\ntests/template-flavors/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd "Test 5"

# ------------------------------------------------------------------------------
head " 6. Custom template directory
    \n    unset TEMPLATE_FLAVOR_PREFIX \
    \n    unset TEMPLATE_OPTIONS \
    \n    TEMPLATE_FLAVOR_DIR=wheezy+whonix-gateway;tests/template-flavors/another_location"
unset TEMPLATE_FLAVOR_PREFIX
unset TEMPLATE_OPTIONS
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway;tests/template-flavors/another_location"
customStep "$0" "pre"
assertTest "customStep $0 pre" "tests/template-flavors/another_location/wheezy+whonix-gateway/test_pre.sh"
assertEnd "Test 6"

# ------------------------------------------------------------------------------
head " 7. Custom template directory for options
    \n    unset TEMPLATE_FLAVOR_PREFIX \
    \n    unset TEMPLATE_OPTIONS \
    \n    TEMPLATE_FLAVOR_DIR=wheezy+whonix-gateway+gnome;tests/template-flavors/another_location"
unset TEMPLATE_FLAVOR_PREFIX
export TEMPLATE_OPTIONS=('gnome')
TEMPLATE_FLAVOR_DIR="wheezy+whonix-gateway+gnome;tests/template-flavors/another_location"
customStep "$0" "pre"
assertTest "customStep $0 pre" "tests/template-flavors/wheezy+whonix-gateway/test_pre.sh\ntests/template-flavors/another_location/wheezy+whonix-gateway+gnome/test_pre.sh"
assertEnd "Test 7"

# ------------------------------------------------------------------------------
export INSTALLDIR="${SCRIPTDIR}/test_copy_location"
head " 8. Copy files
    \n    Just test copying from here to ${INSTALLDIR}"
TEMPLATE_FLAVOR_DIR=""
TEMPLATE_OPTIONS=""
rm -rf "$INSTALLDIR"/*
copy_dirs "files"
ls -l "$INSTALLDIR"
assertTest "ls $INSTALLDIR" "test1\ntest2\ntest3"
assertEnd "Test 8"

# Done
popd
