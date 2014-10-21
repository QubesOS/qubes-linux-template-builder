#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

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
   [[ $TERM != *-m ]] && {
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

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    chroot() {
        local retval
        true ${blue}
        /usr/sbin/chroot "$@"
        retval=$?
        true ${reset}
        return $retval
    }
fi

# ------------------------------------------------------------------------------
# Display messages in color
# ------------------------------------------------------------------------------
info() {
    [[ -z $TEST ]] && echo -e "${bold}${blue}INFO: ${1}${reset}" || :
}

debug() {
    [[ -z $TEST ]] && echo -e "${bold}${green}DEBUG: ${1}${reset}" || :
}

warn() {
    [[ -z $TEST ]] && echo -e "${stout}${yellow}WARNING: ${1}${reset}" || :
}

error() {
    [[ -z $TEST ]] && echo -e "${bold}${red}ERROR: ${1}${reset}" || :
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


customStepExec() {
    local calling_script="$1"
    local step="$2"
    local template_flavor="$3"
    local template_flavor_dir="$4"
    local template_flavor_prefix="$5"

    [[ -z $TEST ]] && debug "Calling script:  ${calling_script}" || :
    [[ -z $TEST ]] && debug "Step:            ${step}" || :
    [[ -z $TEST ]] && debug "Template Flavor: ${template_flavor}" || :
    [[ -z $TEST ]] && debug "Template Dir:    ${template_flavor_dir}" || :
    [[ -z $TEST ]] && debug "Template Prefix: ${template_flavor_prefix}" || :

    splitPath "${calling_script}" path_parts

    # Step: [pre] | [post] (or custom inserted step)
    if [ "${step}" ]; then
        script_name="${path_parts[base]}_${step}${path_parts[dotext]}"
    else
        script_name="${path_parts[base]}${path_parts[dotext]}"
    fi

    if [ -n "${template_flavor}" ]; then
        script="${template_flavor_dir}/${template_flavor_prefix}${template_flavor}/${script_name}"
    else
        script="${template_flavor_dir}/${template_flavor_prefix}/${script_name}"
    fi

    if [ -f "$script" ]; then
        [[ -n $TEST ]] && echo "${script}" || echo "${bold}${under}INFO: Currently running script: ${script}${reset}"
        "$script"
    else
        [[ -z $TEST ]] && debug "${bold}INFO: No CustomStep found for: ${script}${reset}" || :
    fi
}

customCopy() {
    local calling_script="$1"
    local dir="$2"
    local template_flavor="$3"
    local template_flavor_dir="$4"
    local template_flavor_prefix="$5"
    local install_dir="$(readlink -m ${INSTALLDIR})"

    info "copy_dirs(): ${install_dir}"
    if [ -n "${template_flavor}" ]; then
        custom_dir="${template_flavor_dir}/${template_flavor_prefix}${template_flavor}/${dir}"
    else
        custom_dir="${template_flavor_dir}/${template_flavor_prefix}/${dir}"
    fi

    if [ -d "${custom_dir}" ]; then
        dir="${custom_dir}/"
    elif [ -d "${template_flavor_dir}/${dir}" ]; then
        dir="${template_flavor_dir}/${dir}/"
    else
        debug "No extra files to copy for ${dir}"
	return 0
    fi

    dir="$(readlink -m $dir)"
    debug "Copying ${dir}/* ${install_dir}"
    cp -rp "${dir}/"* "${install_dir}"

    if [ -f "${dir}/.facl" ]; then
        debug "Restoring file permissions..."
        pushd "$install_dir"
        {
            setfacl --restore="${dir}/.facl" 2>/dev/null ||:
        }
        popd
    fi
}

templateFlavor() {
    echo ${TEMPLATE_FLAVOR}
}

templateFlavorPrefix() {
    local template=${1-${TEMPLATE_FLAVOR}}
    for element in "${TEMPLATE_FLAVOR_PREFIX[@]}"
    do 
        if [ "${element%;*}" == "${DIST}+${template}" ]; then
            echo ${element#*;}
            return
        fi
    done
    
    echo "${DIST}${TEMPLATE_FLAVOR:++}"
}

templateFlavorDir() {
    local template=${1-${TEMPLATE_FLAVOR}}
    for element in "${TEMPLATE_FLAVOR_DIR[@]}"
    do 
        if [ "${element%;*}" == "${DIST}+${template}" ]; then
            echo ${element#*;}
            return
        fi
    done

    echo "${SCRIPTSDIR}"
}

customParse() {
    local calling_script="$1"
    local step="$2"
    local functionExec="$3"
    local template_flavor="$(templateFlavor)"
    local template_flavor_dir="$(templateFlavorDir ${template_flavor})"
    local template_flavor_prefix="$(templateFlavorPrefix ${template_flavor})"

    ${functionExec} "${calling_script}" \
                    "${step}" \
                    "${template_flavor}" \
                    "${template_flavor_dir}" \
                    "${template_flavor_prefix}"
    

    for template in ${TEMPLATE_OPTIONS[@]}
    do
        template_flavor="$(templateFlavor)+${template}"
        template_flavor_dir="$(templateFlavorDir ${template_flavor})"
        template_flavor_prefix="$(templateFlavorPrefix ${template_flavor})"

        ${functionExec} "${calling_script}" \
                        "${step}" \
                        "${template_flavor}" \
                        "${template_flavor_dir}" \
                        "${template_flavor_prefix}"
    done
}

# ------------------------------------------------------------------------------
# Executes any additional optional configuration steps if the configuration
# scripts exist
# ------------------------------------------------------------------------------
customStep() {
    customParse "$1" "$2" "customStepExec"
}

# ------------------------------------------------------------------------------
# Copy extra file tree to $INSTALLDIR 
# TODO:  Allow copy per step (04_install_qubes.sh-files)
#
# To set file permissions is a PITA since git won't save them and will
# complain heavily if they are set to root only read, so this is the procdure:
#
# 1. Change to the directory that you want to have file permissions retained
# 2. Change all the file permissions / ownership as you want
# 3. Change back to the root of the exta directory (IE: extra-qubes-files)
# 4. getfacl -R . > ".facl"
# 5. If git complains; reset file ownership back to user.  The .facl file stored
#    the file permissions and will be used to reset the file permissions after
#    they get copied over to $INSTALLDIR
# NOTE: Don't forget to redo this process if you add -OR- remove files
# ------------------------------------------------------------------------------
copy_dirs() {
    customParse "" "$1" "customCopy"
}

# $0 is module that sourced vars.sh
echo "${bold}${under}INFO: Currently running script: ${0}${reset}"
