#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
# Description: This library file contains lots of useful bash functions that I've
#   created previously. It's useful to include this lib-core file at the top of a
#   new script you are creating. It brings in lots of tested functionality.
# Handler to avoid multiple sourcing of this file
[[ $_LOADED_LIB_CORE == true ]] && [[ $DEBUG == true ]] &&
    display_debug "Duplicate source attempt on lib-core.sh. Skipping source attempt." &&
    return 0
[[ $_LOADED_LIB_CORE == true ]] && return 0
#============================
#   Script Variables
#============================
#   Assign these before sourcing this file to overwrite defaults
declare _LIB_SETUP_ACTIONS=${_LIB_SETUP_ACTIONS:-true}
declare REQUIRE_BASH_4_4=${REQUIRE_BASH_4_4:-true}
declare REQUIRE_PRIVILEGE=${REQUIRE_PRIVILEGE:-false}
declare ENABLE_TRAP_HANDLERS=${ENABLE_TRAP_HANDLERS:-true}
declare VERBOSE=${VERBOSE:-false}
declare DEBUG=${DEBUG:-false}
declare LIBCORE_LOGS=${LIBCORE_LOGS:-"${HOME}/.logs/"}
#============================
#   Public Global Variables
#============================
#   Don't Change These
#   These variables can be useful to query directly
declare OPERATING_SYSTEM=${OPERATING_SYSTEM:-"Unknown"}
declare OPERATING_SYSTEM_VERSION=${OPERATING_SYSTEM_VERSION:-"Unknown"}
declare IS_PRIVILEGED=false
declare IS_ROOT=false
declare IS_MAC_USER=false
declare HAS_SUDO=false
declare CAN_SUDO=false
#============================
#   Private Global Variables
#============================
#   Don't Change These
declare _SYSTEM_PACKAGE_MANAGER_UPDATED=false
declare _LAST_ELEVATED_CMD_EXIT_CODE=0
declare _LOADED_LIB_CORE=true
#============================
#   Core Functions
#============================
function command_exists {
    which "$1" &>/dev/null || command -v "$1" &>/dev/null
}
function check_privileges {
    [[ $REQUIRE_PRIVILEGE == false ]] && return 0
    [[ $EUID -eq 0 ]] && IS_ROOT=true && IS_PRIVILEGED=true
    command_exists sudo && HAS_SUDO=true && CAN_SUDO=false
    if [[ $HAS_SUDO == true ]]; then
        ! sudo -S true < /dev/null 2> /dev/null &&
            display_warning "Testing user for 'sudo' rights. Exiting after 1 minute." &&
            command_exists timeout && 
                (timeout --foreground 1m sudo -v 2>/dev/null && CAN_SUDO=true && IS_PRIVILEGED=true) \
            || 
                (sudo -v 2>/dev/null && CAN_SUDO=true && IS_PRIVILEGED=true)
    fi
    if [[ $DEBUG == true ]]; then
        display_debug "Found the following privileges for current user:"
        display_debug "\tIS_PRIVILEGED: ${IS_PRIVILEGED}"
        display_debug "\tIS_ROOT: ${IS_ROOT}"
        display_debug "\tHAS_SUDO: ${HAS_SUDO}"
        display_debug "\tCAN_SUDO: ${CAN_SUDO}"
    fi
    sudo -S true < /dev/null 2> /dev/null && local IS_PRIVILEGED=true
    [[ $IS_PRIVILEGED == true ]] && return 0
    [[ $REQUIRE_PRIVILEGE == true ]] && [[ $IS_PRIVILEGED == false ]] &&
        display_error "Privileges are required to run this script. Exiting." && exit 1
    return 1
}
function check_operating_system {
    # Try to determine from '/etc/centos-release'
    [[ -f /etc/centos-release ]] && 
        OPERATING_SYSTEM=$(cat /etc/centos-release | awk '{print $1}') &&
        OPERATING_SYSTEM_VERSION=$(cat /etc/centos-release | awk '{print $4}' | awk -F . '{print $1}') &&
        return 0
    # Try to determine from '/etc/issue'
    [[ -f /etc/issue ]] && OPERATING_SYSTEM=$(cat /etc/issue | awk '{print $1}')
    [[ $OPERATING_SYSTEM == 'Ubuntu' ]] && 
        OPERATING_SYSTEM_VERSION=$(cat /etc/issue | awk '{print $2}' | awk -F . '{print $1}')
    [[ $OPERATING_SYSTEM == 'Debian' ]] &&
        OPERATING_SYSTEM_VERSION=$(cat /etc/issue | awk '{print $3}' | awk -F . '{print $1}')
    # Try to determine from uname
    [[ $OPERATING_SYSTEM == 'Unknown' ]] && OPERATING_SYSTEM=$(uname -a | awk '{print $1}')
    [[ $OPERATING_SYSTEM_VERSION == 'Unknown' ]] && 
        OPERATING_SYSTEM_VERSION=$(uname -a | awk '{print $3}' | awk -F . '{print $1}')
    # Debug Messages
    [[ $DEBUG == true ]] && [[ $OPERATING_SYSTEM_VERSION == 'Unknown' ]] && 
        display_debug "Unknown Operating System. Warn."
    [[ $DEBUG == true ]] && [[ $OPERATING_SYSTEM_VERSION == 'Unknown' ]] && 
        display_debug "Unknown Operating System Version. Warn."
    return 0
}
function run_elevated_cmd {
    # Handle arguments being passed in
    raw_arguments=("$@")
    args=()
    for index in ${!raw_arguments[@]};do
        [[ $index -eq 0 ]] && cmd=${raw_arguments[$index]}
        [[ $index -ne 0 ]] && args+=( ${raw_arguments[$index]} )
    done
    # Determine privileges and run command appropriately
    [[ $IS_PRIVILEGED != true ]] && return 1
    if [[ $IS_ROOT == true ]]; then
        display_info "Running command as root:${CRED} $cmd ${args[@]} ${CE}"
        $cmd ${args[@]}
        return "$?"
    fi
    if [[ $CAN_SUDO == true ]]; then
        if [[ ( $IS_MAC_USER == true ) && ( $cmd == "brew" ) ]]; then
            display_warning "Running brew install as user:${CGREEN} $cmd ${args[@]} ${CE}"
            $cmd ${args[@]}
            return "$?"
        else
            display_info "Running command with sudo:${CGREEN} $cmd ${args[@]} ${CE}"
            sudo $cmd ${args[@]}
            return "$?"
        fi
    fi
    display_warning "Running command without privileges:${CYELLOW} $cmd ${args[@]} ${CE}"
    $cmd ${args[@]}
    return "$?"
}
function safe_copy {
    local src_file="$1"
    local dst_file="${2:-"./"}"
    # grab last char to check if its '/'
    local dst_last_char="${dst_file: -1}"
    # determine src filename without path
    local src_filename="$(echo $src_file | awk -F'/' '{print $NF}')"
    # check if dst is a directory
    if [[ -d "$dst_file" ]]; then
        # If not "dst_file/", then add the '/' for "dst_file/src_filename"
        [[ "$dst_last_char" != '/' ]] && 
            local dst_path="${dst_file}/${src_filename}" \
        ||  local dst_path="${dst_file}${src_filename}"
        # Check if we need to backup any files that might be overwritten
        [[ -e "$dst_path" ]] && backup_file "$dst_path"
    fi
    [[ ! -e "$dst_file" ]] && [[ "$dst_last_char" == '/' ]] &&
            display_info "Making directory: $dst_file" &&
            mkdir -p "$dst_file"
    # Check if dst_file exists and isn't a directory.
    [[ -e "$dst_file" ]] && [[ ! -d "$dst_file" ]] && backup_file "$dst_file"
    # Perform copy operations
    if [[ -d "$src_file" ]];then
        [[ ! -z "$dst_path" ]] && display_info "Copying directory: $src_file -> $dst_path"
        [[ -z "$dst_path" ]] && display_info "Copying directory: $src_file -> $dst_file"
        [[ $DEBUG == true ]] && display_debug && cp -Rv "$src_file" "$dst_file" 2>/dev/null
        [[ $DEBUG == false ]] && cp -R "$src_file" "$dst_file" 2>/dev/null
        return "$?"
    fi
    [[ ! -z "$dst_path" ]] && display_info "Copying file: $src_file -> $dst_path"
    [[ -z "$dst_path" ]] && display_info "Copying file: $src_file -> $dst_file"
    [[ $DEBUG == true ]] && display_debug && cp -v "$src_file" "$dst_file" 2>/dev/null
    [[ $DEBUG == false ]] && cp "$src_file" "$dst_file" 2>/dev/null
    return "$?"
}
function backup_file {
    ratelimit 1
    local src_file="$1"
    local dst_file="$src_file.$(date +%s).backup"
    # Recursive call.
    [[ -e "$dst_file" ]] && display_warning "File exists: $dst_file performing recursive backup call" &&
        backup_file "$src_file" "$dst_file" && return 1
    # Display messages
    [[ -d "$src_file" ]] && display_info "Backing up directory: $src_file -> $dst_file"
    [[ -f "$src_file" ]] && display_info "Backing up file: $src_file -> $dst_file"
    # Perform backup operations
    [[ $DEBUG == true ]] && display_debug && cp -Rv "$src_file" "$dst_file" 2>/dev/null
    [[ $DEBUG == false ]] && cp -R "$src_file" "$dst_file" 2>/dev/null
    return "$?"
}
#============================
#   System Package Management 
#============================
function update_system_package {
    [[ -z "$OPERATING_SYSTEM" ]] && display_error "Unknown OS" && exit 1
    case $OPERATING_SYSTEM in
        Ubuntu | Debian) run_elevated_cmd apt update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true ;;
        CentOS) run_elevated_cmd yum update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true ;;
        Darwin) run_elevated_cmd brew update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true ;;
        *)  display_error "Unknown system package manager. Exiting."; exit 1 ;;
    esac
}
function install_system_package {
    display_bar
    # Assign local variables
    local package_name="$1"
    # Check is command exists, return 0 if it does
    command_exists $package_name && 
        display_success "Package '$package_name' is already installed. Skipping." &&
        _LAST_ELEVATED_CMD_EXIT_CODE=0 && 
        return 0
    # Attempt to install the system package
    display_header "Attempting to install system package: '$package_name'."
    # If system package manager hasn't been updated, then update it
    [[ $_SYSTEM_PACKAGE_MANAGER_UPDATED == false ]] &&
        display_info "Updating system packages" &&
        update_system_package
    # Determine which system package manager to use by OS
    case $OPERATING_SYSTEM in
        Ubuntu|Debian)  
            # Use 'apt'
            run_elevated_cmd apt install -y $package_name &&
                display_success "Successfully installed system package '$package_name'." &&
                return 0
            display_error "Something went wrong during package installation. Skipping." &&
                return 1 ;;
        CentOS) 
            # Use 'yum'
            run_elevated_cmd yum install -y $package_name &&
                display_success "Successfully installed system package '$package_name'." &&
                return 0
            display_error "Something went wrong during package installation. Skipping." &&
                return 1;;
        Darwin) 
            # Use 'brew'
            run_elevated_cmd brew install $package_name && 
                display_success "Successfully installed system package '$package_name'." &&
                return 0
            display_error "Something went wrong during package installation. Skipping." &&
                return 1;;
        *)  display_error "Unknown system package manager. Exiting."; exit 1 ;;
    esac
    # If this didnt return from the case, return unsuccessfully.
    return 1
}
# TODO:
# check_system_package() {
    
# }
#============================
#   Display Functions     
#============================
function _display_message {
    echo -e "$1 $2 ${CE} ${CWHITE} ${@:3} ${CE}"
    # [[ log true ]] log action
}
function newline {
    echo "" && return 0
}
function display_message {
    _display_message $CWHITE "      $@"
}
function display_header {
    _display_message $CPURPLE '[~]' "$@"
}
function display_info {
    _display_message $CBLUE '[*]' "$@"
}
function display_success {
    _display_message $CGREEN '[+]' "$@"
}
function display_warning {
    _display_message $CYELLOW '[!]' "$@"
}
function display_error {
    _display_message $CRED '[-]' "$@"
}
function display_debug {
    [[ -z "$@" ]] && echo -ne "$CPINK [~] DEBUG OUTPUT:${CE} " && return 0
    [[ ! -z "$@" ]] && _display_message $CPINK '[~] DEBUG:' "$@"
}
function display_prompt {
    echo -ne "$CYELLOW [!] ${CE} ${CWHITE} ${@} ${CE}"
}
function display_bar {
    CCOLOR=${1:-$CWHITE}
    echo -e "${1}===============================================================================${CE}"
}
function display_array {
    local _raw_array=($1)
    display_info "Displaying Array:"
    for element in ${_raw_array[@]}; do
        display_message "\tElement: ${element}"
    done 
}
function prompt_user {
    ! check_bash_version && return 1
    # handle associative arguments
    local -A _args
    for _arg in "$@";do
        local key="$(echo "$_arg" | cut -f1 -d=)"
        local value="$(echo "$_arg" | cut -f2 -d=)"
        _args+=([$key]="$value")
    done
    # assign local variables from associative array
    local _message="${_args[message]:-"Do you wish to continue with the program [Y/n]: "}"
    local _default_action="${_args[default_action]:-"Y"}"
    local _warning_message="${_args[warning_message]:-""}"
    local _success_message="${_args[success_message]:-""}"
    local _failure_message="${_args[failure_message]:-""}"
    local _exit_on_failure="${_args[exit_on_failure]:-true}"
    local _error_message="${_args[error_message]:-""}"
    # Prompt user for program execution.
    [[ ! -z "$_warning_message" ]] && display_warning "$_warning_message"
    display_prompt "$_message"
    read _user_response
    # Assign default action
    local user_response=${_user_response:-$_default_action}
    case $user_response in
        [yY][eE][sS]|[yY])  [[ ! -z "$_success_message" ]] && display_success "$_success_message"
            return 0 ;;
        [nN][oO]|[nN]) [[ $_exit_on_failure == true ]] && 
            [[ ! -z "$_failure_message" ]] && display_error "$_failure_message" && exit 1
            [[ ! -z "$_failure_message" ]] && display_warning "$_failure_message"
            return 1 ;;
        *)  [[ ! -z "$_error_message" ]] && display_error "$_error_message"
            exit 1 ;;
    esac
    # If not returned through case then return unsuccessfully.
    return 1
}
#============================
#   Misc Functions  
#============================
function add_terminal_colors {
    # Reset Color
    CE="\033[0m"
    # Text: Common Color Names
    CT="\033[38;5;"
    CRED="${CT}9m"
    CGREEN="${CT}28m"
    CBLUE="${CT}27m"
    CORANGE="${CT}202m"
    CYELLOW="${CT}226m"
    CPINK="${CT}13m"
    CPURPLE="${CT}63m"
    CWHITE="${CT}255m"
    # Text: All Hex Values: C0 - C255
    for HEX in {0..255};do eval "C$HEX"="\\\033[38\;5\;${HEX}m";done
    # Background: Common Color Names
    CB="\033[48;5;"
    CBRED="${CB}9m"
    CBGREEN="${CB}46m"
    CBBLUE="${CB}27m"
    CBORANGE="${CB}202m"
    CBYELLOW="${CB}226m"
    CBPINK="${CB}13m"
    CBPURPLE="${CB}63m"
    # Background: All Hex Values: CB0 - CB255
    for HEX in {0..255};do eval "CB${HEX}"="\\\033[48\;5\;${HEX}m";done
}
function check_bash_version {
    [[ $DEBUG == true ]] && display_debug "Bash Version: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
    # If 4.X, check if it's 4.4 or higher, if 4.4+ then skip.
    [[ "${BASH_VERSINFO[0]}" -eq 4 ]] && [[ "${BASH_VERSINFO[1]}" -gt 3 ]] && return 0
    # if 5.x+ then skip.
    [[ "${BASH_VERSINFO[0]}" -gt 4 ]] && return 0
    # Return false if lower version than 4.4
    return 1
}
function ratelimit {
    local ratelimit="${1:-"1"}"
    local current_runtime=$(date +%s)
    if [[ -s "${LIBCORE_LOGS}/runtime" ]];then
        local last_runtime="$(cat "${LIBCORE_LOGS}/runtime")"
        local target_runtime=$(($last_runtime + $ratelimit))
        local offset=$(($target_runtime - $current_runtime))
        if [[ $DEBUG == true ]];then
            display_debug "Ratelimit Variables:"
            display_debug "\tRatelimit: $ratelimit"
            display_debug "\tLast Runtime: $last_runtime"
            display_debug "\tCurrent Runtime: $current_runtime"
            display_debug "\tTarget Runtime: $target_runtime"
            display_debug "\tOffset: $offset"
        fi
        [[ $target_runtime > $current_runtime ]] && sleep "$offset" && return 1
    fi
    date +%s > "${LIBCORE_LOGS}/runtime"
    return 0
}
#============================
#   Trap Handlers
#============================
function sigint_handler {
    echo
    prompt_user message="Do you wish to continue with the program [y/N]: " \
        warning_message="Signal Interrupt was received, CTRL + C." \
        success_message="Attempting to continue with program execution. There might be errors." \
        failure_message="User chose to not continue. Exiting." \
          error_message="Invalid option. Exiting." \
         default_action="N"
}
function exit_handler {
    local _result="$?"
    [[ $_result -eq 0 ]] && [[ $VERBOSE == true ]] && display_success "Program is exiting succesfully. Good bye."
    [[ $_result -ne 0 ]] && [[ $VERBOSE == true ]] && display_error "Program exited with an error. Good bye."
}
#============================
#   Main Execution / Initialization
#============================
add_terminal_colors
if [[ $_LIB_SETUP_ACTIONS == true ]];then
    [[ $DEBUG == true ]] && display_debug "Loaded lib-core.sh file"
    [[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && [[ $DEBUG == true ]] & 
        display_error "Script requires bash 4.4+" && return 1
    [[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && [[ $DEBUG == false ]] && return 1
    [[ $ENABLE_TRAP_HANDLERS == true ]] && trap sigint_handler SIGINT
    [[ $ENABLE_TRAP_HANDLERS == true ]] && trap exit_handler EXIT
    [[ ! -e "$LIBCORE_LOGS" ]] && display_info "Making log folder: $LIBCORE_LOGS" && mkdir -p "$LIBCORE_LOGS"
    check_operating_system
    check_privileges
fi