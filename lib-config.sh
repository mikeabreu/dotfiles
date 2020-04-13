#!/usr/bin/env bash

# Check for lib-core
if [[ $_LOADED_LIB_CORE == "False" ]];then
    if [[ -e lib-core.sh ]];then
        source lib-core.sh
    else
        echo "Missing lib-core.sh. Exiting."
        exit 1
    fi
fi

# Global Variables
_CONFIG_NAME="config"
_CONFIG_SHELL="zsh"

load_configuration() {
    # Arg 1: profile
    PROFILE_FILENAME=${PROFILE_FILENAME:-1}
    # Check if jq is installed
    which jq >/dev/null
    is_installed=$?
    if [[ is_installed -ne 0 ]];then
        display_error "Command 'jq' is missing from PATH. Exiting."
        exit 1
    fi
    # Load profile
    if [[ $1 == "None" ]];then
        PROFILE_SELECTED='default'
        PROFILE_FILENAME='profile-default.json'
        display_info "Default profile: $PROFILE_SELECTED."
    else
        PROFILE_SELECTED=$(jq '.name' $1)
        display_info "Loaded profile: $PROFILE_SELECTED."
    fi
    display_bar
    # Check that the structure of profile is valid
    _config_validate
    # if [[ $_CONFIG_PACKAGES_FOUND == "True" ]]; then
    #     PROFILE_SYSTEM_PACKAGE_LIST=$(jq '.packages[] | select(.type | contains("system_package")) | .name' $PROFILE_FILENAME | sed 's/"//g')
    # fi

}

_config_validate() {
    _CONFIG_NAME_LENGTH=$(jq '.name | length' $PROFILE_FILENAME)
    _CONFIG_SHELL_LENGTH=$(jq '.shell | length' $PROFILE_FILENAME)

    # Some soft error correction for missing values.
    if [[ $_CONFIG_NAME_LENGTH -eq 0 ]];then
        # Error: No Name Provided
        display_warning "Config Schema: No name was found in config file, using default name of \"default\". Warning."
        _CONFIG_NAME="default"
    fi
    if [[ $_CONFIG_SHELL_LENGTH -eq 0 ]];then
        # Error: No Shell Provided
        display_warning "Config Schema: No shell was found in config file, using default shell of \"zsh\". Warning."
        _CONFIG_NAME="zsh"
    fi
}