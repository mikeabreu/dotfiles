#!/usr/bin/env bash

# Global Variables
_CONFIG_FOUND_NAME="config"
_CONFIG_FOUND_SHELL="zsh"
_CONFIG_FOUND_PACKAGES="False"
_CONFIG_FOUND_SYSTEM_PACKAGES="False"
_CONFIG_FOUND_GITHUB_SUBMODULES="False"

load_configuration() {
    if [[ $1 == "None" ]];then
        PROFILE_SELECTED='headless'
        PROFILE_FILENAME='profile-headless.json'
        display_info "Default profile: $PROFILE_SELECTED."
    else
        PROFILE_SELECTED=$(jq '.name' $1)
        display_info "Loaded profile: $PROFILE_SELECTED."
    fi
    display_bar
    _config_check_structure
    _config_install_system_packages
    _config_install_github_submodule
}

_config_install_system_packages() {
    if [[ $_CONFIG_FOUND_PACKAGES == "True" ]]; then
        PROFILE_SYSTEM_PACKAGE_LIST=$(jq \
            '.packages[] | select(.type | contains("system_package")) | .name' $PROFILE_FILENAME \
            | sed 's/"//g')
        if [[ $_CONFIG_FOUND_SYSTEM_PACKAGES == "True" ]];then
            display_info "Installing system packages from configuration."
            for package in $PROFILE_SYSTEM_PACKAGE_LIST; do
                _supported_operating_systems=$(jq \
                    ".packages[] | select(.name | contains(\"${package}\")) | .operating_systems[]" $PROFILE_FILENAME | sed 's/"//g')
                for SUPPORTED_OS in $_supported_operating_systems;do 
                    if [[ $SUPPORTED_OS == $OPERATING_SYSTEM ]];then
                        install_system_package $package
                    fi
                done
            done
        fi
    fi
}
_config_install_github_submodule() {
    PROFILE_GITHUB_SUBMODULE_LIST=$(jq \
        '.packages[] | select(.type | contains("github_submodule")) | .name' $PROFILE_FILENAME \
        | sed 's/"//g')
    for package in $PROFILE_GITHUB_SUBMODULE_LIST; do
        display_warning "TODO: Install Github Submodule package: $package"
    done
}
_config_check_structure() {
    _CONFIG_FOUND_NAME=$(jq '.name | length' $PROFILE_FILENAME)
    _CONFIG_FOUND_SHELL=$(jq '.shell | length' $PROFILE_FILENAME)
    _CONFIG_FOUND_PACKAGES_LENGTH=$(jq '.packages | length' $PROFILE_FILENAME)

    # Some soft error correction for missing values.
    if [[ $_CONFIG_FOUND_NAME -eq 0 ]];then
        display_warning "Config Schema: No name was found in config file, using default name of \"config\". Warning."
        _CONFIG_NAME="config"
    fi
    if [[ $_CONFIG_FOUND_SHELL -eq 0 ]];then
        display_warning "Config Schema: No shell was found in config file, using default shell of \"zsh\". Warning."
        _CONFIG_NAME="zsh"
    fi
    if [[ $_CONFIG_FOUND_PACKAGES_LENGTH -eq 0 ]];then
        display_warning "Config Schema: No packages were found in config file. Warning." 
        _CONFIG_FOUND_PACKAGES="False"
        _CONFIG_FOUND_SYSTEM_PACKAGES="False"
        _CONFIG_FOUND_GITHUB_SUBMODULES="False"
    else 
        _CONFIG_FOUND_PACKAGES="True"
        _CONFIG_FOUND_SYSTEM_PACKAGES_LENGTH=$(jq \
            '.packages[] | select(.type | contains("system_package")) | length' $PROFILE_FILENAME | head -n 1)
        _CONFIG_FOUND_GITHUB_SUBMODULES_LENGTH=$(jq \
            '.packages[] | select(.type | contains("github_submodule")) | length' $PROFILE_FILENAME | head -n 1)
        # display_message $_CONFIG_FOUND_SYSTEM_PACKAGES_LENGTH
        if [[ $_CONFIG_FOUND_SYSTEM_PACKAGES_LENGTH -eq 0 ]];then
            display_warning "Config Schema: No system packages were found in config file. Warning." 
            _CONFIG_FOUND_SYSTEM_PACKAGES="False"
        else
            _CONFIG_FOUND_SYSTEM_PACKAGES="True"
        fi
        if [[ $_CONFIG_FOUND_GITHUB_SUBMODULES_LENGTH -eq 0 ]];then
            display_warning "Config Schema: No github submodules were found in config file. Warning." 
            _CONFIG_FOUND_GITHUB_SUBMODULES="False"
        else
            _CONFIG_FOUND_GITHUB_SUBMODULES="True"
        fi
    fi
}