#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
[[ $_LOADED_LIB_LOGGING == true ]] && [[ $DEBUG == true ]] &&
    display_debug "Duplicate source attempt on lib-logging.sh. Skipping source attempt." &&
    return 0
[[ $_LOADED_LIB_LOGGING == true ]] && return 0
if [[ $_LOADED_LIB_CORE == false ]];then
    if [[ -e lib-core.sh ]];then
        source lib-core.sh
    elif [[ -e "${HOME}/dotfiles/lib/lib-core.sh" ]];then
        source "${HOME}/dotfiles/lib/lib-core.sh"
    else
        echo "Missing lib-core.sh. Exiting."
        exit 1
    fi
fi

_LIB_SETUP_ACTIONS=true




#============================
#   Main Execution / Initialization
#============================
[[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && display_error "Script requires bash 4.4+" && exit 1
if [[ $_LIB_SETUP_ACTIONS == true ]];then
    [[ $DEBUG == true ]] && display_debug "Loaded lib-core.sh file"
fi