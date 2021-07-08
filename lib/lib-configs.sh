#!/usr/bin/env bash
# Author: Michael Abreu
#========================================================
#   Dependency Check
#========================================================
# Prevent duplicate sourcing
[[ $_LOADED_LIB_CONFIGS == true ]] && {
    [[ $DEBUG == true ]] && display_debug "Skipping: Duplicate source attempt on lib-dotfiles.sh."
    return 0
}
#========================================================
#   Global Variables    
#========================================================
declare -A DOTFILES_PROFILE=()
# Add new options in profile.json by adding them here.
declare -A PROFILE_SCHEMA=(
    [NAME]="string"
    [SHELL]="string"
    [SHELL_FRAMEWORK]="string"
    [SHELL_THEME]="string"
    [SHELL_PLUGINS]="array"
    [SYSTEM_PACKAGES]="array"
    [CONFIGS_PATH]="array"
    [CONFIGS_ETC]="array"
    [CONFIGS_ETC_SYMLINK]="boolean"
    [CUSTOM_INSTALLERS]="array"
)
declare DOTFILES="${HOME}/dotfiles"
# Add new directories here, leave off trailing '/'
declare -A DOTFILES_DIRS=(
    [HOME]="${DOTFILES}/_home"
    [LOGS]="${DOTFILES}/_logs"
    [CONFIGS_PATH]="${DOTFILES}/example_configs/default/home"
    [CONFIGS_ETC]="${DOTFILES}/example_configs/default/home"
    [PROFILES]="${DOTFILES}/example_profiles"
)
declare LIBCORE_LOGS="${DOTFILES_DIRS[LOGS]}"
# Loaded profile otherwise default.json
declare PROFILE_FILENAME="${PROFILE_FILENAME:-"${DOTFILES_DIRS[PROFILES]}/default.json"}"
#========================================================
#   Private Global Variables
#========================================================
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
        failure_message="User exited the program." \
          error_message="Invalid option. Exiting."
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
        display_info "Copying files" "${DOTFILES_PROFILE[CONFIGS_PATH]} -> ${DOTFILES_DIRS[HOME]}"
        cp -vr "${DOTFILES_PROFILE[CONFIGS_PATH]}/." "${DOTFILES_DIRS[HOME]}"
        display_info "Displaying contents of:" "${DOTFILES_DIRS[HOME]}"
        ls -lah ${DOTFILES_DIRS[HOME]}
    }
    ## GNU Stow Linking
    [[ -n "${DOTFILES_PROFILE[CONFIGS_PATH]}" ]] && {
        # GNU STOW _home to ~/
        display_title "GNU Stowing '${DOTFILES_PROFILE[CONFIGS_PATH]}' to '${HOME}'"
        stow -t "${HOME}" "_home"
        # display_info "Displaying contents of:" "${HOME}"
        # ls -lah ${HOME}
        local _files=($( ls -A "${DOTFILES_DIRS[HOME]}" ))
        for _file in "${_files[@]}";do
            [[ $OPERATING_SYSTEM == "Darwin" ]] && {
                    ls -lAh -G "${HOME}/${_file}"
            } || {  ls -lAh --color=always "${HOME}/${_file}"; }
        done
    }
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC]}" ]] && {
        # GNU STOW _etc to /etc/
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
    display_message "${CLGREEN}PROFILE_NAME:${CE} ${CWHITE}\t\t${DOTFILES_PROFILE[NAME]}"
    display_bar
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
    # Configs: Home
    [[ -n "${DOTFILES_PROFILE[CONFIGS_PATH]}" ]] && {
        display_message "${CLGREEN}CONFIGS_PATH:${CE}"
        for config in ${DOTFILES_PROFILE[CONFIGS_PATH]}; do
            display_message "\t${CLGREEN}CONFIG:${CE} ${CWHITE}\t${config}"
        done
    }
    # Configs: etc
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC]}" ]] && {
        display_message "${CLGREEN}CONFIGS_ETC:${CE}"
        for config in ${DOTFILES_PROFILE[CONFIGS_ETC]}; do
            display_message "\t${CLGREEN}CONFIG:${CE} ${CWHITE}\t${config}"
        done
    }
    # Configs: etc_symlink
    [[ -n "${DOTFILES_PROFILE[CONFIGS_ETC_SYMLINK]}" ]] && {
        display_message "${CLGREEN}CONFIGS_ETC_SYMLINK:${CE} ${CWHITE} ${DOTFILES_PROFILE[CONFIGS_ETC_SYMLINK]}"
    }
    # Custom Installers
    [[ -n "${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}" ]] && {
        display_message "${CLGREEN}TOOLS:${CE}"
        for installer in ${DOTFILES_PROFILE[CUSTOM_INSTALLERS]}; do
            display_message "\t${CLGREEN}- Installer:${CE} ${CWHITE} ${installer}"
        done
    }
    display_bar
}
#========================================================
#   Configuration/Setup Functions
#========================================================
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
        HOME)   display_title "Copying files from example_configs/default/home into _home/"
                local -a _configs=($( echo "${DOTFILES_PROFILE[CONFIGS_PATH]}" )) ;;
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
                } || { display_error "Config file doesnt exist: $src_path"; exit 1; }
            } || {  
                # file doesnt have a tag
                local src_path="${config_dir}/${configs[$_filename]}/${_filename}"
                [[ -e "$src_path" ]] && {
                    safe_copy "$src_path" "$target_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Config file doesnt exist: $src_path"; exit 1; }
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
                } || { display_error "Config file doesnt exist: $src_path"; exit 1; }
            } || {  
                # file doesnt have a tag
                local src_path="${config_dir}/${config}"
                [[ -e "$src_path" ]] && {
                    safe_copy "$src_path" "$target_path" "${DOTFILES_DIRS[BACKUP]}"
                } || { display_error "Config file doesnt exist: $src_path"; exit 1; }
            }
        }
    done
}
#========================================================
#   Main Execution / Initialization
#========================================================
[[ $DEBUG == true ]] && display_debug "LIB-DOTFILES: Loaded lib-dotfiles.sh file"
return 0