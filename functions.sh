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
    echo "${bold}${blue}INFO: ${1}${reset}"
}

debug() {
    echo "${bold}${green}DEBUG: ${1}${reset}"
}

warn() {
    echo "${stout}${yellow}WARNING: ${1}${reset}"
}

error() {
    echo "${bold}${red}ERROR: ${1}${reset}"
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

 
# ------------------------------------------------------------------------------
# Executes any additional optional configuration steps if the configuration
# scripts exist
# ------------------------------------------------------------------------------
customStep() {
    info "Checking for any custom $2 configuration scripts for $1..."
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
        echo "${bold}${under}INFO: Currently running script: ${script}${reset}"
        "$script"
    fi
}


# ------------------------------------------------------------------------------
# Copy extra file tree to $INSTALLDIR 
# ------------------------------------------------------------------------------
copy_dirs() {
    DIR="$1"
    info "Entering Copy extra file tree to $INSTALLDIR..."
    if [ -n "${TEMPLATE_FLAVOR}" ]; then
        CUSTOMDIR="$SCRIPTSDIR/custom_${DIST}_${TEMPLATE_FLAVOR}/${DIR}"
    else
        CUSTOMDIR="$SCRIPTSDIR/custom_${DIST}/${DIR}"
    fi

    if [ -d "$CUSTOMDIR" ]; then
        debug "Copying $CUSTOMDIR/* $INSTALLDIR..."
        cp -rp "$CUSTOMDIR/"* "$INSTALLDIR"
    elif [ -d "$SCRIPTSDIR/${DIR}" ]; then
        debug "Copying $SCRIPTSDIR/${DIR}/* $INSTALLDIR"
        cp -rp "$SCRIPTSDIR/${DIR}/"* "$INSTALLDIR"
    else
        debug "No extra files to copy"
    fi
}

# $0 is module that sourced vars.sh
echo "${bold}${under}INFO: Currently running script: ${0}${reset}"
