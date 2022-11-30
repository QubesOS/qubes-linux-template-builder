#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

set -e

VERBOSE=${VERBOSE:-1}
DEBUG=${DEBUG:-0}

containsFlavor() {
    flavor="${1}"
    retval=1
    local template_options

    # shellcheck disable=SC2153
    read -r -a template_options <<<"${TEMPLATE_OPTIONS[@]}"

    # Check the template flavor first
    if [ "${flavor}" == "${TEMPLATE_FLAVOR}" ]; then
        retval=0
    fi

    # Check the template flavors next
    elementIn "${flavor}" "${template_options[@]}" && {
        retval=0
    }

    return ${retval}
}

templateFlavorPrefix() {
    local template_flavor=${1-${TEMPLATE_FLAVOR}}
    local template_flavor_prefix
    # shellcheck disable=SC2153
    read -r -a template_flavor_prefix <<<"${TEMPLATE_FLAVOR_PREFIX[@]}"

    for element in "${template_flavor_prefix[@]}"
    do
        if [ "${element%:*}" == "${DIST}+${template_flavor}" ]; then
            echo "${element#*:}"
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
    local temp_name
    read -r -a temp_name <<<"${template_name//+/ }"
    local index=$(( ${#temp_name[@]}-1 ))

    while [ ${#template_name} -ge 32 ]; do
        template_name=$(printf '%s' "${temp_name[0]}")
        if [ $index -gt 0 ]; then
            template_name+=$(printf '+%s' "${temp_name[@]:1:index}")
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
    dist_name="$(templateNameFixLength "${dist_name}")"

    # Remove and '+' characters from name since they are invalid for name
    dist_name="${dist_name//+/-}"
    echo "${dist_name}"
}

templateName() {
    local template_flavor=${1:-${TEMPLATE_FLAVOR}}
    local template_name
    local template_options
    local template_label
    local template_options_concatenated
    retval=1 # Default is 1; mean no replace happened

    read -r -a template_options <<< "${TEMPLATE_OPTIONS[@]}"

    # Only apply options if $1 was not passed
    if [ -n "${1}" ] || [ -z "${TEMPLATE_OPTIONS[*]}" ]; then
        template_options_concatenated=
    else
        template_options_concatenated=$(printf '+%s' "${template_options[@]}")
    fi

    template_name="$(templateFlavorPrefix "${template_flavor}")${template_flavor}${template_options_concatenated}"

    # shellcheck disable=SC2153
    read -r -a template_label <<<"${TEMPLATE_LABEL[@]}"

    for element in "${template_label[@]}"; do
        if [ "${element%:*}" == "${template_name}" ]; then
            template_name="${element#*:}"
            retval=0
            break
        fi
    done

    # shellcheck disable=SC2005
    echo "$(templateNameFixLength "${template_name}")"
    return $retval
}
