#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

set -e

VERBOSE=${VERBOSE:-1}
DEBUG=${DEBUG:-0}

. ./functions-name.sh

################################################################################
# Global functions
################################################################################
# ------------------------------------------------------------------------------
# Define colors
# ------------------------------------------------------------------------------
colors() {
   ## Thanks to:
   ## http://mywiki.wooledge.org/BashFAQ/037
   ## Variables for terminal requests.
   [[ -t 2 ]] && {
       export alt=$(      tput smcup  || tput ti      ) # Start alt display
       export ealt=$(     tput rmcup  || tput te      ) # End   alt display
       export hide=$(     tput civis  || tput vi      ) # Hide cursor
       export show=$(     tput cnorm  || tput ve      ) # Show cursor
       export save=$(     tput sc                     ) # Save cursor
       export load=$(     tput rc                     ) # Load cursor
       export bold=$(     tput bold   || tput md      ) # Start bold
       export stout=$(    tput smso   || tput so      ) # Start stand-out
       export estout=$(   tput rmso   || tput se      ) # End stand-out
       export under=$(    tput smul   || tput us      ) # Start underline
       export eunder=$(   tput rmul   || tput ue      ) # End   underline
       export reset=$(    tput sgr0   || tput me      ) # Reset cursor
       export blink=$(    tput blink  || tput mb      ) # Start blinking
       export italic=$(   tput sitm   || tput ZH      ) # Start italic
       export eitalic=$(  tput ritm   || tput ZR      ) # End   italic
   [[ ${TERM} != *-m ]] && {
       export red=$(      tput setaf 1|| tput AF 1    )
       export green=$(    tput setaf 2|| tput AF 2    )
       export yellow=$(   tput setaf 3|| tput AF 3    )
       export blue=$(     tput setaf 4|| tput AF 4    )
       export magenta=$(  tput setaf 5|| tput AF 5    )
       export cyan=$(     tput setaf 6|| tput AF 6    )
   }
       export white=$(    tput setaf 7|| tput AF 7    )
       export default=$(  tput op                     )
       export eed=$(      tput ed     || tput cd      )   # Erase to end of display
       export eel=$(      tput el     || tput ce      )   # Erase to end of line
       export ebl=$(      tput el1    || tput cb      )   # Erase to beginning of line
       export ewl=$eel$ebl                                # Erase whole line
       export draw=$(     tput -S <<< '   enacs
                                   smacs
                                   acsc
                                   rmacs' || { \
                   tput eA; tput as;
                   tput ac; tput ae;         } )   # Drawing characters
       export back=$'\b'
   } 2>/dev/null ||:

   export build_already_defined_colors="true"
}

if [ ! "$build_already_defined_colors" = "true" ]; then
   colors
fi

if [ "${VERBOSE}" -ge 2 -o "${DEBUG}" == "1" ]; then
    chroot() {
        # Display `chroot` or `systemd-nspawn` in blue ONLY if VERBOSE >= 2
        # or DEBUG == "1"
        local retval
        true ${blue}

        # Need to capture exit code after running chroot or systemd-nspawn
        # so it will be available as a return value
        if [ "${SYSTEMD_NSPAWN_ENABLE}"  == "1" ]; then
            systemd-nspawn $systemd_bind -D "${INSTALLDIR}" -M "${DIST}" ${1+"$@"} && { retval=$?; true; } || { retval=$?; true; }
        else
            /usr/sbin/chroot "${INSTALLDIR}" ${1+"$@"} && { retval=$?; true; } || { retval=$?; true; }
        fi
        true ${reset}
        return $retval
    }
else
    chroot() {
        if [ "${SYSTEMD_NSPAWN_ENABLE}"  == "1" ]; then
            systemd-nspawn $systemd_bind -D "${INSTALLDIR}" -M "${DIST}" ${1+"$@"}
        else
            /usr/sbin/chroot "${INSTALLDIR}" ${1+"$@"}
        fi
    }
fi

# ------------------------------------------------------------------------------
# Display messages in color
# ------------------------------------------------------------------------------
# Only output text under certain conditions
output() {
    if [ "${VERBOSE}" -ge 1 ] && [[ -z ${TEST} ]]; then
        # Don't echo if -x is set since it will already be displayed via true
        [[ ${-/x} != $- ]] || echo -e ""$@""
    fi
}

outputc() {
    color=${1}
    shift
    output "${!color}"$@"${reset}" || :
}

info() {
    output "${bold}${blue}INFO: "$@"${reset}" || :
}

debug() {
    output "${bold}${green}DEBUG: "$@"${reset}" || :
}

warn() {
    output "${stout}${yellow}WARNING: "$@"${reset}" || :
}

error() {
    output "${bold}${red}ERROR: "$@"${reset}" || :
}

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
    local code=$(declare -p "$array" 2> /dev/null || true)
    local replaced="${code/$array/$export_as}"
    eval ${replaced/declare -/declare -g}
}


# ------------------------------------------------------------------------------
# Checks if the passed element exists in passed array
# $1: Element to check for
# $2: Array to check for element in
#
# Returns 0 if True, or 1 if False
# ------------------------------------------------------------------------------
elementIn () {
  local element
  for element in "${@:2}"; do [[ "$element" == "$1" ]] && return 0; done
  return 1
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

templateDirs() {
    local template_flavor=${1-${TEMPLATE_FLAVOR}}
    local match=0

    # If TEMPLATE_FLAVOR_DIR is not already an array, make it one
    if ! [[ "$(declare -p TEMPLATE_FLAVOR_DIR 2>/dev/null)" =~ ^declare\ -a.* ]] ; then
        TEMPLATE_FLAVOR_DIR=( ${TEMPLATE_FLAVOR_DIR} )
    fi

    for element in "${TEMPLATE_FLAVOR_DIR[@]}"
    do
        # (wheezy+whonix-gateway / wheezy+whonix-gateway+gnome[+++] / wheezy+gnome )
        if [ "${element%:*}" == "$(templateName ${template_flavor})" ]; then
            eval echo -e "${element#*:}"
            match=1

        # Very short name compare (+proxy)
        elif [ "${element:0:1}" == "+" -a "${element%:*}" == "+${template_flavor}" ]; then
            eval echo -e "${element#*:}"
            match=1
        fi
    done

    if [ "${match}" -eq 1 ]; then
        return
    fi

    local template_flavor_prefix="$(templateFlavorPrefix ${template_flavor})"
    if [ -n "${template_flavor}" -a "${template_flavor}" == "+" ]; then
        local dir="${SCRIPTSDIR}/${template_flavor_prefix}"
    elif [ -n "${template_flavor}" ]; then
        local dir="${SCRIPTSDIR}/${template_flavor_prefix}${template_flavor}"
    else
        local dir="${SCRIPTSDIR}"
    fi

    echo "${dir}"
}

exists() {
    filename="${1}"

    if [ -e "${filename}" ] && ! elementIn "${filename}" "${GLOBAL_CACHE[@]}"; then
        # Cache $script
        #
        # GLOBAL_CACHE is declared in the `getFileLocations` function and is later
        # renamed to a name passed into the function as $1 to allow scripts using
        # the function to have access to the array
        GLOBAL_CACHE["${#GLOBAL_CACHE[@]}"]="${filename}"
        return 0
    fi
    return 1
}

templateFile() {
    local file="$1"
    local suffix="$2"
    local template_flavor="$3"
    local template_dirs="$(templateDirs "${template_flavor}")"

    splitPath "${file}" path_parts

    for template_dir in ${template_dirs[@]}; do
        # No template flavor
        if [ -z "${template_flavor}" ]; then
            if [ "${suffix}" ]; then
                exists "${SCRIPTSDIR}/${path_parts[base]}_${suffix}${path_parts[dotext]}" || true
            else
                exists "${SCRIPTSDIR}/${path_parts[base]}${path_parts[dotext]}" || true
            fi
            return
        fi

        # Locate file in directory named after flavor
        if [ "${suffix}" ]; then
            # Append suffix to filename (before extension)
            # `minimal` is the template_flavor being used in comment example

            # (TEMPLATE_FLAVOR_DIR/minimal/packages_qubes_suffix.list)
            exists "${template_dir}/${template_flavor}/${path_parts[base]}_${suffix}${path_parts[dotext]}" || true

            # (TEMPLATE_FLAVOR_DIR/minimal/packages_qubes_suffix.list)
            exists "${template_dir}/${template_flavor}/${path_parts[base]}_${suffix}${path_parts[dotext]}" || true

            # (TEMPLATE_FLAVOR_DIR/packages_qubes_suffix.list)
            exists "${template_dir}/${path_parts[base]}_${suffix}${path_parts[dotext]}" || true

            # (TEMPLATE_FLAVOR_DIR/packages_qubes_minimal_suffix.list)
            exists "${template_dir}/${path_parts[base]}_${suffix}_${template_flavor}${path_parts[dotext]}" || true

            # (SCRIPTSDIR/packages_qubes_minimal_suffix.list)
            exists "${SCRIPTSDIR}/${path_parts[base]}_${suffix}_${template_flavor}${path_parts[dotext]}" || true
        else
            # (TEMPLATE_FLAVOR_DIR/minimal/packages_qubes.list)
            exists "${template_dir}/${template_flavor}/${path_parts[base]}${path_parts[dotext]}" || true

            # (TEMPLATE_FLAVOR_DIR/minimal/packages_qubes_minimal.list)
            exists "${template_dir}/${template_flavor}/${path_parts[base]}_${template_flavor}${path_parts[dotext]}" || true

            # (TEMPLATE_FLAVOR_DIR/packages_qubes.list)
            exists "${template_dir}/${path_parts[base]}${path_parts[dotext]}" || true

            # (TEMPLATE_FLAVOR_DIR/packages_qubes_minimal.list)
            exists "${template_dir}/${path_parts[base]}_${template_flavor}${path_parts[dotext]}" || true

            # (SCRIPTSDIR/packages_qubes_minimal.list)
            exists "${SCRIPTSDIR}/${path_parts[base]}_${template_flavor}${path_parts[dotext]}" || true
        fi
    done
}

copyTreeExec() {
    local source_dir="$1"
    local dir="$2"
    local template_flavor="$3"
    local target_dir="$4"

    local template_dirs="$(templateDirs ${template_flavor})"

    for template_dir in ${template_dirs[@]}; do
        local source_dir="$(readlink -m ${source_dir:-${template_dir}}/${dir})"
        local target_dir="$(readlink -m ${target_dir:-${INSTALLDIR}})"

        if ! [ -d "${source_dir}" ]; then
            debug "No extra files to copy for ${dir}"
            return 0
        fi

        debug "Copying ${source_dir}/* ${target_dir}"
        cp -rp "${source_dir}/." "${target_dir}"

        if [ -f "${source_dir}/.facl" ]; then
            debug "Restoring file permissions..."
            pushd "${target_dir}"
            {
                setfacl --restore="${source_dir}/.facl" 2>/dev/null ||:
                rm -f .facl
            }
            popd
        fi
    done
}

callTemplateFunction() {
    local calling_script="$1"
    local calling_arg="$2"
    local functionExec="$3"
    local template_flavor="${TEMPLATE_FLAVOR}"

    ${functionExec} "${calling_script}" \
                    "${calling_arg}" \
                    "${template_flavor}"

    # Find a $DIST sub-directory
    ${functionExec} "${calling_script}" \
                    "${calling_arg}" \
                    "+"

    for option in ${TEMPLATE_OPTIONS[@]}
    do
        # Long name (wheezy+whonix-gateway+proxy)
        ${functionExec} "${calling_script}" \
                        "${calling_arg}" \
                        "${TEMPLATE_FLAVOR}+${option}"

        # Short name (wheezy+proxy)
        ${functionExec} "${calling_script}" \
                        "${calling_arg}" \
                        "${option}"
    done

    # If template_flavor exists, also check on base distro
    if [ -n "${template_flavor}" ]; then
        ${functionExec} "${calling_script}" \
                        "${calling_arg}"
    fi
}

# ------------------------------------------------------------------------------
# Will return all files that match pattern of suffix
# Example:
#   filename = packages.list
#   suffix = ${DIST} (wheezy)
#
# Will look for a file name packages_wheezy.list in:
#   the $SCRIPTSDIR; beside original
#   the $SCRIPTSDIR/$DIST (wheezy) directory
#   any included template module directories ($SCRIPTSDIR/gnome)
#
# All matches are returned and each will be able to be used
# ------------------------------------------------------------------------------
getFileLocations() {
    local return_global_var=$1
    local filename="$2"
    local suffix="$3"
    local function="templateFile"

    unset GLOBAL_CACHE
    declare -gA GLOBAL_CACHE

    callTemplateFunction "${filename}" "${suffix}" "${function}"
    setArrayAsGlobal GLOBAL_CACHE $return_global_var

    if [ ! ${#GLOBAL_CACHE[@]} -eq 0 ]; then
        debug "Smart files located for: '${filename##*/}' (suffix: ${suffix}):"
        for filename in "${GLOBAL_CACHE[@]}"; do
            debug "${filename}"
        done
    fi
}

# ------------------------------------------------------------------------------
# Executes any additional optional configuration steps if the configuration
# scripts exist
#
# Will find all scripts with
# Example:
#   filename = 04_install_qubes.sh
#   suffix = post
#
# Will look for a file name 04_install_qubes_post in:
#   the $SCRIPTSDIR; beside original
#   the $SCRIPTSDIR/$DIST (wheezy) directory
#   any included template module directories ($SCRIPTSDIR/gnome)
#
# All matches are executed
# ------------------------------------------------------------------------------
buildStep() {
    local filename="$1"
    local suffix="$2"
    unset build_step_files

    info "Locating buildStep files: ${filename##*/} suffix: ${suffix}"
    getFileLocations "build_step_files" "${filename}" "${suffix}"

    for script in "${build_step_files[@]}"; do
        if [ -e "${script}" ]; then
            # Test module expects raw  output back only used to asser test results
            if [[ -n ${TEST} ]]; then
                echo "${script}"
            else
                output "${bold}${under}INFO: Currently running script: ${script}${reset}"
            fi

            # Execute $script
            "${script}"
        fi
    done
}

# ------------------------------------------------------------------------------
# Copy extra file tree to ${INSTALLDIR}
# TODO:  Allow copy per step (04_install_qubes.sh-files)
#
# To set file permissions is a PITA since git won't save them and will
# complain heavily if they are set to root only read, so this is the procdure:
#
# 1. Change to the directory that you want to have file permissions retained
# 2. Change all the file permissions / ownership as you want
# 3. Change back to the root of the exta directory (IE: extra-qubes-files)
# 4. Manually restore facl's: setfacl --restore=.facl
# 5. Manually create facl backup used after copying: getfacl -R . > .facl
# 6. If git complains; reset file ownership back to user.  The .facl file stored
#    the file permissions and will be used to reset the file permissions after
#    they get copied over to ${INSTALLDIR}
# NOTE: Don't forget to redo this process if you add -OR- remove files
# ------------------------------------------------------------------------------
copyTree() {
    local dir="$1"
    local source_dir="$2"
    local target_dir="$3"
    local function="copyTreeExec"

    if [ -z "${source_dir}" ]; then
        splitPath "${0}" path_parts
        if [ -d "${path_parts[dir]}/${dir}" ]; then
            copyTreeExec "${path_parts[dir]}" "${dir}" "" ""
        else
            callTemplateFunction "" "${dir}" "${function}"
        fi
    else
        copyTreeExec "${source_dir}" "${dir}" "" "${target_dir}"
    fi
}

# $0 is module that sourced vars.sh
output "${bold}${under}INFO: Currently running script: ${0}${reset}"
