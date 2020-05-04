#!/usr/bin/env bash
echo "LIB-DOTFILES: Shell: $SHELL"
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
    [SHELL_PLUGINS]="array"
    [SYSTEM_PACKAGES]="array"
    [CONFIGS_HOME]="array"
    [CONFIGS_ETC]="array"
    [CONFIGS_ETC_SYMLINK]="boolean"
    [TOOLS]="array"
    [CUSTOM_INSTALLERS]="array"
)
declare DOTFILES="${HOME}/dotfiles"
declare -A DOTFILES_DIRS=(
    [HOME]="${DOTFILES}/_home"
    [ETC]="${DOTFILES}/_etc"
    [BIN]="${DOTFILES}/_bin"
    [LOGS]="${DOTFILES}/_logs"
    [BACKUP]="${DOTFILES}/_backup"
    [TMP]="${DOTFILES}/_tmp"
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
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS]}" ]] && {
        # Shell Plugins
        install_shell_plugins "${DOTFILES_PROFILE[SHELL_PLUGINS]}" "${DOTFILES_DIRS[HOME]}"
    }
    [[ -n "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}" ]] && {
        # System Packages
        install_system_packages "${DOTFILES_PROFILE[SYSTEM_PACKAGES]}"
        display_bar
    }
    [[ -n "${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}" ]] && {
        # Custom Installers
        install_custom_installers "${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}" "${DOTFILES}"
    }
    #############
    ### Setup ###
    #############
    [[ -n "${DOTFILES_PROFILE[CONFIGS_HOME]}" ]] && {
        # Configs: Home
        setup_configs name="HOME" \
            config_dir="${DOTFILES_DIRS[CONFIGS_HOME]}" \
            target_dir="${DOTFILES_DIRS[HOME]}"
    }
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC]}" ]] && {
        # Configs: ETC
        setup_configs name="ETC" \
            config_dir="${DOTFILES_DIRS[CONFIGS_ETC]}" \
            target_dir="${DOTFILES_DIRS[ETC]}"
    }
    [[ -n "${DOTFILES_PROFILE[TOOLS]}" ]] && {
        # Tools
        setup_tools "${DOTFILES_PROFILE[TOOLS]}"
    }
    #####################
    ### Configuration ###
    #####################

    ####################
    ### Link Folders ###
    ####################
    [[ -n "${DOTFILES_PROFILE[CONFIGS_HOME]}" ]] && {
        # GNU STOW _home to ~/
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
        # GNU STOW _etc to /etc/
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
    [[ -n "${DOTFILES_PROFILE[SHELL_PLUGINS]}" ]] && {
        display_message "${CGREEN}SHELL_PLUGINS:${CE}"
        for plugin in ${DOTFILES_PROFILE[SHELL_PLUGINS]}; do
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
    # Custom Installers
    [[ -n "${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}" ]] && {
        display_message "${CGREEN}TOOLS:${CE}"
        for installer in ${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}; do
            display_message "\t${CGREEN}- Installer:${CE} ${CWHITE} ${installer}"
        done
    }
    display_bar
}
#============================
#   Configuration/Setup Functions
#============================
function setup_profile_data {
    # Reads profile.json and creates an assoc array, DOTFILES_PROFILE, with all found key/values
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
function setup_configs {
    # handle associative arguments
    local -A _args
    for _arg in "$@";do
        local key="$( echo "$_arg" | cut -f1 -d= )"
        local value="$( echo "$_arg" | cut -f2 -d= )"
        _args+=([$key]="$value")
    done
    # setup variables from args
    local name="${_args[name]:-""}"
    local config_dir="${_args[config_dir]:-""}"
    local target_dir="${_args[target_dir]:-""}"
    local -A configs=()
    local -A tags=()
    # display title and setup dirty config_files
    case "$name" in
        HOME)   display_title "Copying files from configs/home into _home/"
                local -a _configs=($( echo "${DOTFILES_PROFILE[CONFIGS_HOME]}" )) ;;
        ETC)    display_title "Copying files from configs/etc into _etc/"
                local -a _configs=($( echo "${DOTFILES_PROFILE[CONFIGS_ETC]}" )) ;;
        *)      display_error "Bad configs: $name" && exit 1 ;;
    esac
    # Clean config strings into configs[filename]="path" and tags[filename]="tag"
    for _config in "${_configs[@]}";do
        # Attempt to get the filename without the tag | 'tag=filename' or 'path/tag=filename'
        # Empty if no tag is there.
        local _filename="$( echo $_config   | 
            awk -F'=' '{$1 = ""; print $0}' | 
            sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' )"
        [[ -z "$_filename" ]] && {
            # file doesnt have a tag. Set _filename to raw filename
            local _filename="$_config"
            local _tag=""
        } || {
            # file has a tag, grab it
            local _tag="$( echo $_config    | 
                awk -F'=' '{print $1}'      | 
                awk -F'/' '{print $NF}'     | 
                sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' )"
        }
        # Determine if file has a path
        [[ "$_config" == *"/"* ]] && {
            # file has a path
            [[ "${_config: -1}" == '/' ]] && {
                # file has '/' as ending character, ignore it
                local __config="${_config::-1}"
                local _path="${__config%/*}"
            } || {
                # file doesnt have '/' as ending character
                local _path="${_config%/*}"
            }
        } || {
            # file doesnt have a path
            local _path=""
        }
        # Setup clean configs_file with key=filename value=path
        configs[$_filename]="$_path"
        # Setup clean tags with key=filename value=tag
        tags[$_filename]="$_tag"
    done
    # Copy over cleaned config files to target_dir
    for _filename in "${!configs[@]}";do
        [[ -n "${configs[$_filename]}" ]] && {
            # file has a path
            local target_path="${target_dir}/${configs[$_filename]}/$_filename"
            [[ ! -e "${target_dir}/${configs[$_filename]}" ]] && {
                # Create the file path in _home for files to be copied to
                mkdir -p "${target_dir}/${configs[$_filename]}"
            }
            [[ $VERBOSE == true ]] && display_info "Filename: $_filename"
            [[ -n "${tags[$_filename]}" ]] && {
                # file has a tag
                [[ $VERBOSE == true ]] && display_info "Tag: ${tags[$_filename]}"
                local src_path="${config_dir}/${configs[$_filename]}/${tags[$_filename]}=${_filename}"
                [[ -e "$src_path" ]] && {
                    safe_copy "$src_path" "$target_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $src_path"; exit 1; }
            } || {  
                # file doesnt have a tag
                local src_path="${config_dir}/${configs[$_filename]}/${_filename}"
                [[ -e "$src_path" ]] && {
                    safe_copy "$src_path" "$target_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $src_path"; exit 1; }
            }
        } || {
            # file doesnt have a path
            local target_path="${target_dir}/$_filename"
            [[ $VERBOSE == true ]] && display_info "Filename: $_filename"
            [[ -n "${tags[$_filename]}" ]] && {
                # file has a tag
                [[ $VERBOSE == true ]] && display_info "Tag: ${tags[$_filename]}"
                local src_path="${config_dir}/${tags[$_filename]}=${_filename}"
                [[ -e "$src_path" ]] && {
                    safe_copy "$src_path" "$target_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $src_path"; exit 1; }
            } || {  
                # file doesnt have a tag
                local src_path="${config_dir}/${config}"
                [[ -e "$src_path" ]] && {
                    safe_copy "$src_path" "$target_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Exiting: Config file doesnt exist: $src_path"; exit 1; }
            }
        }
    done
}
#============================
#   Main Execution / Initialization
#============================
[[ $DEBUG == true ]] && display_debug "Loaded lib-dotfiles.sh file"
return 0