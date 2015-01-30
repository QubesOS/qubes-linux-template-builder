#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

set -e

VERBOSE=${VERBOSE:-1}
DEBUG=${DEBUG:-0}

templateFlavorPrefix() {
    local template_flavor=${1-${TEMPLATE_FLAVOR}}

    # If TEMPLATE_FLAVOR_PREFIX is not already an array, make it one
    if ! [[ "$(declare -p TEMPLATE_FLAVOR_PREFIX 2>/dev/null)" =~ ^declare\ -a.* ]] ; then 
        TEMPLATE_FLAVOR_PREFIX=( ${TEMPLATE_FLAVOR_PREFIX} )
    fi

    for element in "${TEMPLATE_FLAVOR_PREFIX[@]}"
    do 
        if [ "${element%:*}" == "${DIST}+${template_flavor}" ]; then
            echo ${element#*:}
            return
        fi
    done
    
    echo "${DIST}${template_flavor:++}"
}

templateNameDist() {
    local dist_name="${1}"
    template_name="$(templateName)" && dist_name="${template_name}"

    # XXX: Temp hack to shorten name
    if [ ${#dist_name} -ge 32 ]; then
        if [ ${#template_name} -lt 32 ]; then
            dist_name="${template_name}"
        else
            dist_name="${dist_name:0:31}"
        fi
    fi

    # Remove and '+' characters from name since they are invalid for name
    dist_name="${dist_name//+/-}"
    echo ${dist_name}
}

templateName() {
    local template_flavor=${1-${TEMPLATE_FLAVOR}}
    retval=1 # Default is 1; mean no replace happened

    # Only apply options if $1 was not passed
    if [ -n "${1}" ]; then
        local template_options=
    else
        local template_options="${TEMPLATE_OPTIONS// /+}"
    fi

    local template_name="$(templateFlavorPrefix ${template_flavor})${template_flavor}${template_options:++}${template_options}"

    # If TEMPLATE_LABEL is not already an array, make it one
    if ! [[ "$(declare -p TEMPLATE_LABEL 2>/dev/null)" =~ ^declare\ -a.* ]] ; then 
        TEMPLATE_LABEL=( ${TEMPLATE_LABEL} )
    fi

    for element in "${TEMPLATE_LABEL[@]}"; do
        if [ "${element%:*}" == "${template_name}" ]; then
            template_name="${element#*:}"
            retval=0
            break
        fi
    done

    if [ ${#template_name} -ge 32 ]; then
        error "Template name is greater than 31 characters: ${template_name}"
        error "Please set an alias"
        error "Exiting!!!"
        exit 1
    fi

    echo ${template_name}
    return $retval
}
