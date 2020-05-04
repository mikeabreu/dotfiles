#!/usr/bin/env bash
# Author: Michael Abreu
#============================
#   Dependency Check
#============================
# Prevent duplicate sourcing of library
[[ $_LOADED_LIB_DOTFILES == true ]] && {
    [[ $DEBUG == true ]] && display_debug "Skipping: Duplicate source attempt on lib-dotfiles.sh."
    return 0
}
# Load lib-core.sh
[[ $_LOADED_LIB_CORE == false ]] && {
    [[ -e "lib-core.sh" ]] && source "lib-core.sh" || { 
        echo "LIB-DOTFILES: Failed to load lib-core.sh"; exit 1; }
    [[ -e "${HOME}/dotfiles/lib/lib-core.sh" ]] && source "${HOME}/dotfiles/lib/lib-core.sh" || {
        echo "LIB-DOTFILES: Failed to load ${HOME}/dotfiles/lib/lib-core.sh"; exit 1; }
    [[ $_LOADED_LIB_CORE == false ]] && { echo "LIB-DOTFILES: Missing lib-core.sh. Exiting."; exit 1; }
}
# Load lib-installers.sh
[[ $_LOADED_LIB_INSTALLERS == false ]] && {
    [[ -e "lib-installers.sh" ]] && source "lib-installers.sh" || { 
            echo "LIB-DOTFILES: Failed to load lib-installers.sh"; exit 1; }
    [[ -e "${HOME}/dotfiles/lib/lib-installers.sh" ]] && source "${HOME}/dotfiles/lib/lib-installers.sh" || {
        echo "LIB-DOTFILES: Failed to load ${HOME}/dotfiles/lib/lib-installers.sh"; exit 1; }
    [[ $_LOADED_LIB_INSTALLERS == false ]] && { echo "LIB-DOTFILES: Missing lib-core.sh. Exiting."; exit 1; }
}
# Enforce bash requirement for assoc arrays
REQUIRE_BASH_4_4=true
[[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && {
    [[ $DEBUG == true ]] && display_debug "LIB-DOTFILES: Requires bash 4.4+"
    return 1
}
#============================
#   Global Variables    
#============================
declare -A DOTFILES_PROFILE=()
declare -A PROFILE_SCHEMA=(
    [NAME]="string"
    [SHELL]="string"
    [SHELL_FRAMEWORK]="string"
    [SHELL_THEME]="string"
    [SHELL_PLUGINS_NO_INSTALLATION]="array"
    [SHELL_PLUGINS_TO_INSTALL]="array"
    [SYSTEM_PACKAGES]="array"
    [CONFIGS_HOME]="array"
    [CONFIGS_ETC]="array"
    [CONFIGS_ETC_SYMLINK]="boolean"
    [TOOLS]="array"
)
declare DOTFILES="${HOME}/dotfiles"
declare -A DOTFILES_DIRS=(
    [HOME]="${DOTFILES}/_home"
    [ETC]="${DOTFILES}/_etc"
    [BIN]="${DOTFILES}/_bin"
    [LOGS]="${DOTFILES}/_logs"
    [BACKUP]="${DOTFILES}/_backup"
    [CONFIGS]="${DOTFILES}/configs"
    [CONFIGS_HOME]="${DOTFILES}/configs/home"
    [CONFIGS_ETC]="${DOTFILES}/configs/etc"
    [TOOLS]="${DOTFILES}/tools"
)
declare LIBCORE_LOGS="${DOTFILES_DIRS[LOGS]}"
declare PROFILE_FILENAME="${PROFILE_FILENAME:-"${DOTFILES}/profiles/default.json"}"
#============================
#   Private Global Variables
#============================
declare _LOADED_LIB_DOTFILES=true
#============================
#   Core Functions
#============================
function load_profile {
    local _file=${PROFILE_FILENAME:-1}
    # Check if file is exists and is readable
    [[ ! -r "$_file" ]] && display_error "Profile filename is not valid. Exiting." && exit 1
    # Check if jq is installed
    ! command_exists jq && display_error "Command 'jq' is missing from PATH. Exiting." && exit 1
    # Attempt to read the profile and setup DOTFILES_PROFILE
    setup_profile_data "$_file"
    [[ -z "${DOTFILES_PROFILE[@]}" ]] && display_error "Couldn't successfully load the profile. Exiting." && exit 1
    # Setup directories if needed
    for _dir in "${!DOTFILES_DIRS[@]}";do
        [[ ! -d "${DOTFILES_DIRS[${_dir}]}" ]] && {
            [[ -e "${DOTFILES_DIRS[${_dir}]}" ]] && { 
                [[ $DEBUG == true ]] && display_debug "Removing blocking file for '${_dir}' dir."
                backup_file "${DOTFILES_DIRS[${_dir}]}"
                rm -fr "${DOTFILES_DIRS[${_dir}]}"
                mkdir -p "${DOTFILES_DIRS[${_dir}]}" 
            } || { mkdir "${DOTFILES_DIRS[${_dir}]}"; }
        }
    done
}
function install_profile {
    # Show the user the loaded profile
    display_profile
    # Prompt user to continue with installation
    prompt_user message="Do you wish to install this profile [Y/n]:" \
        success_message="Continuing with profile installation." \
        failure_message="User chose to not load profile. Exiting." \
          error_message="Invalid option. Exiting."
    ####################
    ### Installation ###
    ####################
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
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS_TO_INSTALL]}" ]] && {
        # Shell Plugins
        install_shell_plugins "${DOTFILES_PROFILE[SHELL_PLUGINS_TO_INSTALL]}" "${DOTFILES_DIRS[HOME]}"
    }
    [[ -n "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}" ]] && {
        # System Packages
        install_system_packages "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}"
        display_bar
    }
    #############
    ### Setup ###
    #############
    [[ -n "${DOTFILES_PROFILE[CONFIGS_HOME]}" ]] && {
        # Configs: Home
        setup_configs config_name="HOME" \
            config_directory="${DOTFILES_DIRS[CONFIGS_HOME]}" \
            target_directory="${DOTFILES_DIRS[HOME]}"
    }
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC]}" ]] && {
        # Configs: ETC
        setup_configs config_name="ETC" \
            config_directory="${DOTFILES_DIRS[CONFIGS_ETC]}" \
            target_directory="${DOTFILES_DIRS[ETC]}"
    }
    [[ -n "${DOTFILES_PROFILE[TOOLS]}" ]] && {
        # Tools
        setup_tools "${DOTFILES_PROFILE[TOOLS]}"
    }
    #####################
    ### Configuration ###
    #####################
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS_TO_INSTALL]}" ]] || 
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS_NO_INSTALLATION]}" ]] && {
        # Shell Plugins
        configure_shell_plugins shell="${DOTFILES_PROFILE[SHELL]}" \
            plugins="$( echo "${DOTFILES_PROFILE[SHELL_PLUGINS_TO_INSTALL]}" "${DOTFILES_PROFILE[SHELL_PLUGINS_NO_INSTALLATION]}" )"
            
    }
    ####################
    ### Link Folders ###
    ####################
    [[ -n "${DOTFILES_PROFILE[CONFIGS_HOME]}" ]] && {
        display_bar
        display_title "GNU Stowing '${DOTFILES_DIRS[HOME]}/_home' to '${HOME}'"
        stow -t "${HOME}/" "_home/"
        local _files=($( ls -A "${DOTFILES_DIRS[HOME]}" ))
        for _file in "${_files[@]}";do
            [[ $OPERATING_SYSTEM == "Darwin" ]] && {
                    /bin/ls -lAh -G "${HOME}/${_file}"
            } || {  /bin/ls -lAh --color=always "${HOME}/${_file}"; }
        done
    }
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC]}" ]] && {
        display_bar
        display_title "GNU Stowing '${DOTFILES_DIRS[HOME]}/_etc' to '/etc'"
        stow -t "/etc/" "_etc/"
        local _files=($( ls -A "${DOTFILES_DIRS[ETC]}" ))
        for _file in "${_files[@]}";do
            [[ $OPERATING_SYSTEM == "Darwin" ]] && {            
                    /bin/ls -lAhG "/etc/${_file}"
            } || {  /bin/ls -lAh --color=always "/etc/${_file}"; }
        done
    }
    display_bar
}
function display_profile {
    display_title "Displaying the loaded profile."
    display_bar
    # Name
    display_message "${CGREEN}PROFILE_NAME:${CE} ${CWHITE} ${DOTFILES_PROFILE[NAME]}"
    display_bar
    # Shell
    display_message "${CGREEN}SHELL:${CE} ${CWHITE} ${DOTFILES_PROFILE[SHELL]}"
    # Shell Framework
    [[ -n "${DOTFILES_PROFILE[SHELL_FRAMEWORK]}" ]] && {
        display_message "${CGREEN}SHELL_FRAMEWORK:${CE} ${CWHITE} ${DOTFILES_PROFILE[SHELL_FRAMEWORK]}"
    }
    # Shell Theme
    [[ -n "${DOTFILES_PROFILE[SHELL_THEME]}" ]] && {
        display_message "${CGREEN}SHELL_THEME:${CE} ${CWHITE} ${DOTFILES_PROFILE[SHELL_THEME]}"
    }
    # Shell Plugins
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS_NO_INSTALLATION]}" ]] && {
        display_message "${CGREEN}SHELL_PLUGINS_NO_INSTALLATION:${CE}"
        for plugin in ${DOTFILES_PROFILE[SHELL_PLUGINS_NO_INSTALLATION]}; do
            display_message "\t${CGREEN}- PLUGIN:${CE} ${CWHITE} ${plugin}"
        done
    }
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS_TO_INSTALL]}" ]] && {
        display_message "${CGREEN}SHELL_PLUGINS_TO_INSTALL:${CE}"
        for plugin in ${DOTFILES_PROFILE[SHELL_PLUGINS_TO_INSTALL]}; do
            display_message "\t${CGREEN}- PLUGIN:${CE} ${CWHITE} ${plugin}"
        done
    }
    # System Packages
    [[ -n "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}" ]] && {
        display_message "${CGREEN}SYSTEM_PACKAGES:${CE}"
        for package in ${DOTFILES_PROFILE[SYSTEM_PACKAGES]}; do
            display_message "\t${CGREEN}- PACKAGE:${CE} ${CWHITE} ${package}"
        done
    }
    # Configs: Home
    [[ -n "${DOTFILES_PROFILE[CONFIGS_HOME]}" ]] && {
        display_message "${CGREEN}CONFIGS_HOME:${CE}"
        for config in ${DOTFILES_PROFILE[CONFIGS_HOME]}; do
            display_message "\t${CGREEN}- CONFIG:${CE} ${CWHITE} ${config}"
        done
    }
    # Configs: etc
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC]}" ]] && {
        display_message "${CGREEN}CONFIGS_ETC:${CE}"
        for config in ${DOTFILES_PROFILE[CONFIGS_ETC]}; do
            display_message "\t${CGREEN}- CONFIG:${CE} ${CWHITE} ${config}"
        done
    }
    # Configs: etc_symlink
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC_SYMLINK]}" ]] && {
        display_message "${CGREEN}CONFIGS_ETC_SYMLINK:${CE} ${CWHITE} ${DOTFILES_PROFILE[CONFIGS_ETC_SYMLINK]}"
    }
    # Tools
    [[ -n "${DOTFILES_PROFILE[TOOLS]}" ]] && {
        display_message "${CGREEN}TOOLS:${CE}"
        for tool in ${DOTFILES_PROFILE[TOOLS]}; do
            display_message "\t${CGREEN}- TOOL:${CE} ${CWHITE} ${tool}"
        done
    }
    display_bar
}
#============================
#   Configuration/Setup Functions
#============================
function setup_profile_data {
    local profile_file="$1"
    [[ ! -r "$profile_file" ]] && display_error "Cannot read profile file: $profile_file" && exit 1
    [[ $DEBUG == true ]] && display_debug "Determing profile variables from file or default."
    for key in "${!PROFILE_SCHEMA[@]}";do
        # key: [ NAME SHELL SHELL_FRAMEWORK ... ]
        # PROFILE_SCHEMA[$key]: [ string string string string array ... ]
        setup_var_data "$key" "${PROFILE_SCHEMA[$key]}" "$profile_file"
        # If value is null, set it to "" for empty checks in bash.
        [[ "${DOTFILES_PROFILE[$key]}" == "null" ]] && DOTFILES_PROFILE[$key]=""
    done
}
function setup_var_data {
    local -A _types=(
        [string]="string"
        [boolean]="boolean"
        [array]="array"
        [number]="number"
    )
    local varname="$1"
    local data_type="${2:-"${_types[string]}"}"
    local profile_file="$3"
    local lower_varname="$(echo "$1" | tr "[:upper:]" "[:lower:]")"
    local upper_varname="$(echo "$1" | tr "[:lower:]" "[:upper:]")"
    case "$data_type" in
        ${_types[string]})
            jq ".${lower_varname} | length" "$profile_file" &>/dev/null && {
                DOTFILES_PROFILE[${upper_varname}]="$(jq ".${lower_varname}" "$profile_file" | sed 's/"//g')"
                [[ $DEBUG == true ]] && display_debug "DOTFILES_PROFILE[${upper_varname}]: ${DOTFILES_PROFILE[${upper_varname}]}"
            } ;;
        ${_types[boolean]})
            DOTFILES_PROFILE[${varname}]="$(jq ".${lower_varname}" "$profile_file")"
            [[ $DEBUG == true ]] && [[ -n "${DOTFILES_PROFILE[$varname]}" ]] && 
                display_debug "DOTFILES_PROFILE[${varname}]: ${DOTFILES_PROFILE[${varname}]}"
            ;;
        ${_types[array]})
            jq ".${lower_varname} | length" "$profile_file" &>/dev/null && {
                DOTFILES_PROFILE[${upper_varname}]="$(_arr=(
                    $(jq ".${lower_varname}" "$profile_file" | sed -e 's/"//g' -e 's/\[//g' -e 's/\]//g' -e 's/\,//g')
                    ) && echo "${_arr[@]}")"
                [[ $DEBUG == true ]] && display_debug "DOTFILES_PROFILE[${upper_varname}]: ${DOTFILES_PROFILE[${upper_varname}]}"
            } ;;
        ${_types[number]})
            jq ".${varname} | length" "$profile_file" &>/dev/null && {
                DOTFILES_PROFILE[${varname}]="$(jq ".${varname}" "$profile_file" | sed 's/"//g')"
                [[ $DEBUG == true ]] && display_debug "DOTFILES_PROFILE[${varname}]: ${DOTFILES_PROFILE[${varname}]}"
            } ;;
        *) [[ $DEBUG == true ]] && display_debug "Invalid type passed to set_var_number: $data_type for varname: $varname" && return 1 ;;
    esac
}
function setup_configs {
    # handle associative arguments
    local -A _args
    for _arg in "$@";do
        local key="$( echo "$_arg" | cut -f1 -d= )"
        local value="$( echo "$_arg" | cut -f2 -d= )"
        _args+=([$key]="$value")
    done
    # setup variables
    local config_name="${_args[config_name]:-""}"
    local config_directory="${_args[config_directory]:-""}"
    local target_directory="${_args[target_directory]:-""}"
    # display title and setup config_files
    case "$config_name" in
        HOME)   display_title "Copying files from configs/home into _home/"
                local _config_files=($( echo "${DOTFILES_PROFILE[CONFIGS_HOME]}" )) ;;
        ETC)    display_title "Copying files from configs/etc into _etc/"
                local _config_files=($( echo "${DOTFILES_PROFILE[CONFIGS_ETC]}" )) ;;
        *)      display_error "Bad configs: $config_name" && exit 1 ;;
    esac
    # Setup assoc array for cleaned config data and tags
    local -A config_files=()
    local -A tags=""
    # Clean config data
    for config in "${_config_files[@]}";do
        # Attempt to get the filename without the tag '[A-Za-z0-9]='
        local config_file="$( echo $config | awk -F'=' '{$1 = ""; print $0}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' )"
        [[ -z "$config_file" ]] && {
            # file doesnt have a tag.
            local config_file="$config"
            local tag=""
        } || {
            # file has a tag
            local tag="$( echo $config | awk -F'=' '{print $1}' | awk -F'/' '{print $NF}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' )"
        }
        # Determine if file has a file
        [[ "$config" == *"/"* ]] && {
            # file has a path
            [[ "${config: -1}" == '/' ]] && {
                # file has '/' as ending character, ignore it
                local _config="${config::-1}"
                local path="${_config%/*}"
            } || {
                # file doesnt have '/' as ending character
                local path="${config%/*}"
            }
        } || {
            # file doesnt have a path
            local path=""
        }
        # Set assoc pair of [config_filename]="path/to/filename || blank for no path"
        config_files[$config_file]="$path"
        # Set assoc pair of [config_filename]="tag || blank for no tag"
        [[ -n "$tag" ]] && tags[$config_file]="$tag"
    done
    # Copy over files to target_directory
    for config in "${!config_files[@]}";do
        [[ -n "${config_files[$config]}" ]] && {
            # file has a path
            local rel_path="${target_directory}/${config_files[$config]}/$config"
            # mkdir -p "${target_directory}/${config_files[$config]}"
            [[ $VERBOSE == true ]] && display_info "Filename: $config"
            [[ -n "${tags[$config]}" ]] && {
                # file has a tag
                [[ $VERBOSE == true ]] && display_info "Tag: ${tags[$config]}"
                local config_file="${config_directory}/${config_files[$config]}/${tags[$config]}=${config}"
                [[ -e "$config_file" ]] && {
                    safe_copy "$config_file" "$rel_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $config_file"; exit 1; }
            } || {  
                # file doesnt have a tag
                local config_file="${config_directory}/${config_files[$config]}/${config}"
                [[ -e "$config_file" ]] && {
                    safe_copy "$config_file" "$rel_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $config_file"; exit 1; }
            }
        } || {
            # file doesnt have a path
            local rel_path="${target_directory}/$config"
            [[ $VERBOSE == true ]] && display_info "Filename: $config"
            [[ -n "${tags[$config]}" ]] && {
                # file has a tag
                [[ $VERBOSE == true ]] && display_info "Tag: ${tags[$config]}"
                local config_file="${config_directory}/${tags[$config]}=${config}"
                [[ -e "$config_file" ]] && {
                    safe_copy "$config_file" "$rel_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $config_file"; exit 1; }
            } || {  
                # file doesnt have a tag
                local config_file="${config_directory}/${config}"
                [[ -e "$config_file" ]] && {
                    safe_copy "$config_file" "$rel_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $config_file"; exit 1; }
            }
        }
    done
}
function configure_shell_plugins {
    # handle associative arguments
    local -A _args
    for _arg in "$@";do
        local key="$(echo "$_arg" | cut -f1 -d=)"
        local value="$(echo "$_arg" | cut -f2 -d=)"
        _args+=([$key]="$value")
    done
    # assign local variables from associative arguments
    local dotfiles_home="${_args[dotfiles_home]:-"${HOME}/dotfiles/_home"}"
    local plugins="${_args[plugins]:-""}"
    local _shell="${_args[shell]}"
    case "$_shell" in
        # Add Custom Shell RC File Here
        zsh)    local _rc=".zshrc"  ;;
        bash)   local _rc=".bashrc" ;;
        *) display_error "Couldn't find rc file for shell: $shell"; return 1 ;;
    esac
    # TODO
    display_bar
    display_title "Configuring plugins into file: '${dotfiles_home}/${_rc}'"
    [[ -r "${dotfiles_home}/${_rc}" ]] && {
        local _plugins="$(echo "${plugins[@]}")"
        [[ $OPERATING_SYSTEM == "Darwin" ]] && {
            # MacOS
            sed -i "" -e "s#%%PLUGINS%%#${_plugins}#" "${dotfiles_home}/${_rc}"
        } || {
            # Not MacOS
            sed -i -e "s#%%PLUGINS%%#${_plugins}#" "${dotfiles_home}/${_rc}"
        }
    } || { display_error "Couldn't find your rc file at: '${dotfiles_home}/${_rc}'"; }
}
#============================
#   Main Execution / Initialization
#============================
[[ $DEBUG == true ]] && display_debug "Loaded lib-dotfiles.sh file"
return 0