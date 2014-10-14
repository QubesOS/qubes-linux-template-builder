# ------------------------------------------------------------------------------
# Global variables and functions
# ------------------------------------------------------------------------------
# The codename of the debian version to install.
# jessie = testing, wheezy = stable
DEBIANVERSION=$DIST

# Location to grab debian packages
#DEBIAN_MIRROR=http://http.debian.net/debian
#DEBIAN_MIRROR=http://mirror.csclub.uwaterloo.ca/debian/
DEBIAN_MIRROR=http://ftp.ca.debian.org/debian/

# XXX: Is this even used?
EXTRAPKGS="openssh-clients,screen,vim-nox,less"

# XXX: Is this even used?
QUBESDEBIANGIT="http://dsg.is/qubes/"

# XXX: Is this even used?
# make runs the scripts with sudo -E, so HOME is set to /home/user during
# build, which does not exist. We need to write to $HOME/.gnupg so set it
# to something valid.
HOME=/root


# ------------------------------------------------------------------------------
# Takes an array and exports it a global variable
#
# $1: Array to export
# $2: Global variable name to use for export
#
# http://ihaveabackup.net/2012/01/29/a-workaround-for-passing-arrays-in-bash/
#
# ------------------------------------------------------------------------------
setArrayAsGlobal() {
    local array="$1"
    local export_as="$2"
    local code=$(declare -p "$array")
    local replaced="${code/$array/$export_as}"
    eval ${replaced/declare -/declare -g}
} 


# ------------------------------------------------------------------------------
# Spilts the path and returns an array of parts
#
# $1: Full path of file to split
# $2: Global variable name to use for export
# Returns:
# ([full]='original name' [dir]='directory' [base]='filename' [ext]='extension')
#
# Original concept path split from:
# https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
#
# ------------------------------------------------------------------------------
splitPath() {

    local return_global_var=$2
    local filename="${1##*/}"                  # Strip longest match of */ from start
    local dir="${1:0:${#1} - ${#filename}}"    # Substring from 0 thru pos of filename
    local base="${filename%.[^.]*}"            # Strip shortest match of . plus at least one non-dot char from end
    local ext="${filename:${#base} + 1}"       # Substring from len of base thru end
    if [ "$ext" ]; then
        local dotext=".$ext"
    else
        local dotext=""
    fi
    if [[ -z "$base" && -n "$ext" ]]; then     # If we have an extension and no base, it's really the base
        base=".$ext"
        ext=""
        dotext=""
    fi

    declare -A PARTS=([full]="$1" [dir]="$dir" [base]="$base" [ext]="$ext" [dotext]="$dotext")
    setArrayAsGlobal PARTS $return_global_var
}

 
# ------------------------------------------------------------------------------
# Executes any additional optional configuration steps if the configuration
# scripts exist
# ------------------------------------------------------------------------------
customStep() {
    echo "--> Checking for any custom $2 configuration scripts for $1..."
    splitPath "$1" path_parts

    if [ "$2" ]; then
        script_name="${path_parts[base]}_$2${path_parts[dotext]}"
    else
        script_name="${path_parts[base]}${path_parts[dotext]}"
    fi

    if [ -n "${TEMPLATE_FLAVOR}" ]; then
        script="$SCRIPTSDIR/custom_${DIST}_${TEMPLATE_FLAVOR}/${script_name}"
    else
        script="$SCRIPTSDIR/custom_${DIST}/${script_name}"
    fi

    if [ -f "$script" ]; then
        "$script"
    fi
}


# ------------------------------------------------------------------------------
# Copy extra file tree to $INSTALLDIR 
# ------------------------------------------------------------------------------
copy_dirs() {
    DIR="$1"
    if [ -n "${TEMPLATE_FLAVOR}" ]; then
        CUSTOMDIR="$SCRIPTSDIR/custom_${DIST}_${TEMPLATE_FLAVOR}/${DIR}"
    else
        CUSTOMDIR="$SCRIPTSDIR/custom_${DIST}/${DIR}"
    fi

    if [ -d "$CUSTOMDIR" ]; then
        cp -rp "$CUSTOMDIR/"* "$INSTALLDIR"
    elif [ -d "$SCRIPTSDIR/${DIR}" ]; then
        cp -rp "$SCRIPTSDIR/${DIR}/"* "$INSTALLDIR"
    fi
}
