#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

set -e

VERBOSE=${VERBOSE:-1}
DEBUG=${DEBUG:-0}

containsFlavor() {
    flavor="${1}"
    retval=1

    # Check the template flavor first
    if [ "${flavor}" == "${TEMPLATE_FLAVOR}" ]; then
        retval=0
    fi

    # Check the template flavors next
    elementIn "${flavor}" ${TEMPLATE_OPTIONS[@]} && {
        retval=0
    }

    return ${retval}
}

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
    
    # If template_flavor only contains a '+'; send back $DIST
    if [ "${template_flavor}" == "+" ]; then
        echo "${DIST}"
    else    
        echo "${DIST}${template_flavor:++}"
    fi
}

templateNameFixLength() {
    local template_name="${1}"
    local temp_name=(${template_name//+/ })
    local index=$(( ${#temp_name[@]}-1 ))

    while [ ${#template_name} -ge 32 ]; do
        template_name=$(printf '%s' ${temp_name[0]})
        if [ $index -gt 0 ]; then
            template_name+=$(printf '+%s' ${temp_name[@]:1:index})
        fi
        (( index-- ))
        if [ $index -lt 1 ]; then
            template_name="${template_name:0:31}"
        fi
    done

    echo "${template_name}"
}

templateNameDist() {
    local dist_name="${1}"
    template_name="$(templateName)" && dist_name="${template_name}"

    # Automaticly correct name length if it's greater than 32 chars
    dist_name="$(templateNameFixLength ${template_name})"

    # Remove and '+' characters from name since they are invalid for name
    dist_name="${dist_name//+/-}"
    echo ${dist_name}
}

templateName() {
    local template_flavor=${1-${TEMPLATE_FLAVOR}}
    retval=1 # Default is 1; mean no replace happened

    # Only apply options if $1 was not passed
    if [ -n "${1}" ] || [ "X${TEMPLATE_OPTIONS}" == "X" ]; then
        local template_options=
    else
        local template_options=$(printf '+%s' ${TEMPLATE_OPTIONS[@]})
    fi

    local template_name="$(templateFlavorPrefix ${template_flavor})${template_flavor}${template_options}"

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

    echo "$(templateNameFixLength ${template_name})"
    return $retval
}
