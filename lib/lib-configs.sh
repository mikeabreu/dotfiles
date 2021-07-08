#!/usr/bin/env bash
# Author: Michael Abreu
#========================================================
#   Dependency Check
#========================================================
# Prevent duplicate sourcing
[[ $_LOADED_LIB_CONFIGS == true ]] && {
    [[ $DEBUG == true ]] && display_debug "Skipping: Duplicate source attempt on lib-configs.sh."
    return 0
}
! check_bash_version && {
    return 0
}
#========================================================
#   Global Variables    
#========================================================
declare -A DOTFILES_PROFILE=()
declare -A PROFILE_SCHEMA=(
    [NAME]="string"
    [SHELL]="string"
    [SHELL_FRAMEWORK]="string"
    [SHELL_THEME]="string"
    [SHELL_PLUGINS]="array"
    [SYSTEM_PACKAGES]="array"
    [CONFIGS_PATH]="array"
    [CUSTOM_INSTALLERS]="array"
)
declare DOTFILES="${HOME}/dotfiles"
declare -A DOTFILES_DIRS=(
    [HOME]="${DOTFILES}/_home"
    [CONFIGS_PATH]="${DOTFILES}/example_configs/default/home"
    [PROFILES]="${DOTFILES}/example_profiles"
)
declare PROFILE_FILENAME="${PROFILE_FILENAME:-"${DOTFILES_DIRS[PROFILES]}/default.json"}"
declare _LOADED_LIB_CONFIGS=true
#========================================================
#   Core Functions
#========================================================
function load_profile {
    local _file=${PROFILE_FILENAME:-1}
    # Check if file exists and is readable
    [[ ! -r "$_file" ]] && display_error "Profile file could not be found at path:" "$_file" && exit 1
    # Check if jq is installed
    ! command_exists jq && display_error "Command 'jq' is missing from PATH. Exiting." && exit 1
    # Attempt to read the profile and setup DOTFILES_PROFILE
    setup_profile_data "$_file"
    [[ -z "${DOTFILES_PROFILE[@]}" ]] && display_error "Couldn't successfully load the profile. Exiting." && exit 1
    # Setup directories if needed
    for _dir in "${!DOTFILES_DIRS[@]}";do
        [[ ! -d "${DOTFILES_DIRS[${_dir}]}" ]] && {
            [[ -e "${DOTFILES_DIRS[${_dir}]}" ]] && { 
                display_error "Blocking folder:" "${_dir}"
                exit 1;
            } || { mkdir "${DOTFILES_DIRS[${_dir}]}"; }
        }
    done
}
function install_profile {
    # Show the user the loaded profile
    display_profile
    [[ $SKIP_PROMPTS == false ]] && {
        # Prompt user to continue with installation
        prompt_user message="Do you wish to install this profile [Y/n]:" \
            success_message="Continuing with profile installation." \
            failure_message="User exited the program." \
            error_message="Invalid option. Exiting."
    }
    # Copy profile into .loaded_profile for sync operations.
    display_bar
    display_info "Copying profile into .loaded_profile"
    cp -vf $PROFILE_FILENAME "${DOTFILES}/.loaded_profile"
    ## Installation
    # Shell
    install_shell "${DOTFILES_PROFILE[SHELL]}"
    [[ -n "${DOTFILES_PROFILE[SHELL_FRAMEWORK]}" ]] && {
        # Shell Framework
        install_shell_framework "${DOTFILES_PROFILE[SHELL_FRAMEWORK]}" "${DOTFILES_DIRS[HOME]}"
    }
    [[ -n "${DOTFILES_PROFILE[SHELL_THEME]}" ]] && {
        # Shell Theme
        install_shell_theme "${DOTFILES_PROFILE[SHELL_THEME]}" "${DOTFILES_DIRS[HOME]}"
    }
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS]}" ]] && {
        # Shell Plugins
        install_shell_plugins "${DOTFILES_PROFILE[SHELL_PLUGINS]}" "${DOTFILES_DIRS[HOME]}"
    }
    [[ -n "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}" ]] && {
        # System Packages
        install_system_packages "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}"
    }
    [[ -n "${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}" ]] && {
        # Custom Installers
        install_custom_installers "${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}" "${DOTFILES}"
    }
    [[ -n "${DOTFILES_PROFILE[CONFIGS_PATH]}" ]] && {
        # Configs: Home
        # setup_configs name="HOME" \
        #     config_dir="${DOTFILES_PROFILE[CONFIGS_PATH]}" \
        #     target_dir="${DOTFILES_DIRS[HOME]}"
        local _files=($(/bin/ls -A "${DOTFILES_DIRS[HOME]}" ))
        display_title "Copying configuration files to ${DOTFILES_DIRS[HOME]} and then symlinking to ${HOME}/"
        display_bar
        # Copy files from profile to _home
        display_info "Copying files" "${DOTFILES_PROFILE[CONFIGS_PATH]} -> ${DOTFILES_DIRS[HOME]}"
        cp -vr "${DOTFILES_PROFILE[CONFIGS_PATH]}/." "${DOTFILES_DIRS[HOME]}"
        display_info "Displaying contents of:" "${DOTFILES_DIRS[HOME]}"
        ls -lah ${DOTFILES_DIRS[HOME]}
        # Check each file in _home against ~/ and backup anything found in ~/.
        display_info "Checking for existing files in $HOMME"
        for _file in "${_files[@]}";do
            [[ ! -h "${HOME}/${_file}" ]] && {
                display_warning "File exists and isn't a symlink:" "${HOME}/$_file"
                ls -lahd "${HOME}/$_file"
                display_info "Moving file:" "${HOME}/$_file -> ${HOME}/${_file}.bkp"
                mv -v ${HOME}/$_file ${HOME}/${_file}.bkp
                ls -lahd "${HOME}/${_file}.bkp"
            }
        done
        # GNU STOW _home to ~/
        display_info "Symlinking:" "${DOTFILES_DIRS[HOME]} -> ${HOME}'"
        stow -t "${HOME}" "_home"
        # Display linked files/folders in ~/
        display_info "Displaying symlinks in:" "${HOME}"
        for _file in "${_files[@]}";do
            [[ $OPERATING_SYSTEM == "Darwin" ]] && {
                    ls -lAhG "${HOME}/${_file}"
            } || {  ls -lAh --color=always "${HOME}/${_file}"; }
        done
    }
    display_bar
}
function display_profile {
    display_title "Displaying the loaded profile."
    display_bar
    # Name
    display_message "${CLGREEN}PROFILE_NAME:${CE} ${CWHITE}\t\t${DOTFILES_PROFILE[NAME]}"
    display_bar
    # Configs Path
    [[ -n "${DOTFILES_PROFILE[CONFIGS_PATH]}" ]] && {
        display_message "${CLGREEN}CONFIGS_PATH:${CE} ${CWHITE}\t\t${DOTFILES_PROFILE[CONFIGS_PATH]}"
    }
    # Shell
    display_message "${CLGREEN}SHELL:${CE} ${CWHITE}\t\t\t${DOTFILES_PROFILE[SHELL]}"
    # Shell Framework
    [[ -n "${DOTFILES_PROFILE[SHELL_FRAMEWORK]}" ]] && {
        display_message "${CLGREEN}SHELL_FRAMEWORK:${CE} ${CWHITE}\t${DOTFILES_PROFILE[SHELL_FRAMEWORK]}"
    }
    # Shell Theme
    [[ -n "${DOTFILES_PROFILE[SHELL_THEME]}" ]] && {
        display_message "${CLGREEN}SHELL_THEME:${CE} ${CWHITE}\t\t${DOTFILES_PROFILE[SHELL_THEME]}"
    }
    # Shell Plugins
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS]}" ]] && {
        display_message "${CLGREEN}SHELL_PLUGINS:${CE}"
        for plugin in ${DOTFILES_PROFILE[SHELL_PLUGINS]}; do
            display_message "\t${CLGREEN}PLUGIN:${CE} ${CWHITE}\t${plugin}"
        done
    }
    # System Packages
    [[ -n "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}" ]] && {
        display_message "${CLGREEN}SYSTEM_PACKAGES:${CE}"
        for package in ${DOTFILES_PROFILE[SYSTEM_PACKAGES]}; do
            display_message "\t${CLGREEN}PACKAGE:${CE} ${CWHITE}\t${package}"
        done
    }
    # Custom Installers
    [[ -n "${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}" ]] && {
        display_message "${CLGREEN}CUSTOM_INSTALLERS:${CE}"
        for installer in ${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}; do
            display_message "\t${CLGREEN}INSTALLER:${CE} ${CWHITE}\t${installer}"
        done
    }
    display_bar
}
#========================================================
#   Configuration/Setup Functions
#========================================================
function setup_profile_data {
    # Reads a profile.json file and creates an assoc array, DOTFILES_PROFILE, with all found key/values
    local profile_file="$1"
    [[ ! -r "$profile_file" ]] && display_error "Cannot read profile file: $profile_file" && exit 1
    [[ $DEBUG == true ]] && display_debug "Determing profile variables from file or default."
    for key in "${!PROFILE_SCHEMA[@]}";do
        # For every key/value in PROFILE_SCHEMA, setup that key/value in DOTFILES_PROFILE from profile json
        #   key: [ NAME SHELL SHELL_FRAMEWORK ... ]
        #   PROFILE_SCHEMA[$key]: [ string string string string array ... ]
        # setup_var_data "KEY" "TYPE" "PROFILE.JSON" > DOTFILES_PROFILE[KEY]="Value from PROFILE.JSON for KEY"
        setup_var_data "$key" "${PROFILE_SCHEMA[$key]}" "$profile_file"
        # If value is null, set it to "" for empty checks in bash.
        [[ "${DOTFILES_PROFILE[$key]}" == "null" ]] && DOTFILES_PROFILE[$key]=""
    done
}
function setup_var_data {
    # function that handles the mapping of key/values from profile.json into DOTFILES_PROFILE
    local varname="$1"
    local data_type="${2:-"string"}"
    local profile_file="$3"
    local lower_varname="$(echo "$1" | tr "[:upper:]" "[:lower:]")"
    local upper_varname="$(echo "$1" | tr "[:lower:]" "[:upper:]")"
    case "$data_type" in
        string) jq ".${lower_varname} | length" "$profile_file" &>/dev/null && {
                    DOTFILES_PROFILE[${upper_varname}]="$(jq ".${lower_varname}" "$profile_file" | sed 's/"//g')"
                    [[ $DEBUG == true ]] && 
                        display_debug "DOTFILES_PROFILE[${upper_varname}]: ${DOTFILES_PROFILE[${upper_varname}]}"
                } ;;
        boolean)
                DOTFILES_PROFILE[${varname}]="$(jq ".${lower_varname}" "$profile_file")"
                [[ $DEBUG == true ]] && [[ -n "${DOTFILES_PROFILE[$varname]}" ]] && 
                    display_debug "DOTFILES_PROFILE[${varname}]: ${DOTFILES_PROFILE[${varname}]}" ;;
        array)
                jq ".${lower_varname} | length" "$profile_file" &>/dev/null && {
                    DOTFILES_PROFILE[${upper_varname}]="$(_arr=(
                        $(jq ".${lower_varname}" "$profile_file" | sed -e 's/"//g' -e 's/\[//g' -e 's/\]//g' -e 's/\,//g')
                        ) && echo "${_arr[@]}")"
                    [[ $DEBUG == true ]] && 
                        display_debug "DOTFILES_PROFILE[${upper_varname}]: ${DOTFILES_PROFILE[${upper_varname}]}"
                } ;;
        number)
                jq ".${varname} | length" "$profile_file" &>/dev/null && {
                    DOTFILES_PROFILE[${varname}]="$(jq ".${varname}" "$profile_file" | sed 's/"//g')"
                    [[ $DEBUG == true ]] && display_debug "DOTFILES_PROFILE[${varname}]: ${DOTFILES_PROFILE[${varname}]}"
                } ;;
        *)      [[ $DEBUG == true ]] &&
                    display_debug "Invalid type passed to setup_var_data: $data_type for varname: $varname"
                return 1 ;;
    esac
}
#========================================================
#   Main Execution / Initialization
#========================================================
[[ $DEBUG == true ]] && display_debug "LIB-CONFIGS: Loaded lib-configs.sh file"
return 0