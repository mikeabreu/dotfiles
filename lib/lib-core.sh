#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
#============================
#   Script Configurable Variables
#============================
REQUIRE_BASH_4_4=${REQUIRE_BASH_4_4:-true}
REQUIRE_PRIVILEGE=${REQUIRE_PRIVILEGE:-false}
VERBOSE=${VERBOSE:-false}
DEBUG=${DEBUG:-false}
#============================
#   Public Global Variables
#============================
OPERATING_SYSTEM=${OPERATING_SYSTEM:-"Unknown"}
OPERATING_SYSTEM_VERSION=${OPERATING_SYSTEM_VERSION:-"Unknown"}
IS_PRIVILEGED=false
IS_ROOT=false
IS_MAC_USER=false
HAS_SUDO=false
CAN_SUDO=false
#============================
#   Private Global Variables
#============================
_SYSTEM_PACKAGE_MANAGER_UPDATED=false
_LAST_ELEVATED_CMD_EXIT_CODE=0
_LOADED_LIB_CORE=true

#============================
#   Core Functions
#============================
function command_exists() {
    which "$1" >/dev/null 2>/dev/null || command -v "$1" >/dev/null 2>/dev/null
}
function file_exists() {
    if [[ -e "$1" ]];then return 0; fi
    return 1
}
function check_privileges() {
    [[ $REQUIRE_PRIVILEGE == false ]] && return 0
    if [[ $OPERATING_SYSTEM == "Darwin" ]]; then
        IS_MAC_USER=true
    fi
    if [[ $EUID -eq 0 ]]; then
        # User is root
        IS_ROOT=true
        IS_PRIVILEGED=true
    fi
    command_exists sudo && _result=true || _result=false
    if [[ $_result == true ]];then
        # sudo is installed
        HAS_SUDO=true
        display_warning "Testing user for 'sudo' rights. Exiting after 1 minute."
        timeout --foreground 1m sudo -v 2>/dev/null
        sudo_validation=$?
        if [[ $sudo_validation -eq 0 ]]; then
            # User can use sudo, *Dangerous check* unclear commands allowed.
            CAN_SUDO=true
            IS_PRIVILEGED=true
        else
            CAN_SUDO=false
            IS_PRIVILEGED=false
        fi
    fi
    # VERBOSE PRINTING
    if [[ $VERBOSE == true ]]; then
        display_info "Found the following privileges for current user:"
        display_message "IS_MAC_USER: ${IS_MAC_USER}"
        display_message "IS_PRIVILEGED: ${IS_PRIVILEGED}"
        display_message "IS_ROOT: ${IS_ROOT}"
        display_message "HAS_SUDO: ${HAS_SUDO}"
        display_message "CAN_SUDO: ${CAN_SUDO}"
    fi
    [[ $IS_MAC_USER == false ]] &&
    [[ $IS_PRIVILEGED == false ]] &&
        display_error "Privileges are required to run this script. Exiting." && exit 1
}
function check_operating_system() {
    if [[ -f /etc/centos-release ]];then
        # CentOS
        OPERATING_SYSTEM=$(cat /etc/centos-release | awk '{print $1}')
        OPERATING_SYSTEM_VERSION=$(cat /etc/centos-release | awk '{print $4}' | awk -F . '{print $1}')
    elif [[ -f /etc/issue ]];then
        # Ubuntu or Debian or unsupported
        OPERATING_SYSTEM=$(cat /etc/issue | awk '{print $1}')
        if [[ $OPERATING_SYSTEM == 'Ubuntu' ]];then
            # Ubuntu
            OPERATING_SYSTEM_VERSION=$(cat /etc/issue | awk '{print $2}' | awk -F . '{print $1}')
        elif [[ $OPERATING_SYSTEM == 'Debian' ]];then
            # Debian
            OPERATING_SYSTEM_VERSION=$(cat /etc/issue | awk '{print $3}' | awk -F . '{print $1}')
        else
            # Unsupported
            OPERATING_SYSTEM_VERSION='Unknown'
            display_warning "Unknown Operating System Version. Warn."
        fi
    else
        # macOS or unsupported OS
        OPERATING_SYSTEM=$(uname -a | awk '{print $1}')
        OPERATING_SYSTEM_VERSION=$(uname -a | awk '{print $3}' | awk -F . '{print $1}')
    fi
    if [[ $OPERATING_SYSTEM == 'Unknown' ]];then 
        display_error "Unknown Operating System. Exiting."
        display_bar
        exit 1
    fi
}
function run_elevated_cmd() {
    # Function Details:
    #   Syntax: run_cmd <command> [arguments]
    #   
    # Global Options:
    #   Set 'REQUIRE_PRIVILEGE=true' globally to require privileges to run commands.
    #
    # Example:
    #   run_cmd apt update
    
    # Handle arguments being passed in
    raw_arguments=("$@")
    args=()
    for index in ${!raw_arguments[@]};do
        if [[ $index -eq 0 ]]; then
            cmd=${raw_arguments[$index]}
        else
            args+=( ${raw_arguments[$index]} )
        fi
    done
    # Determine privileges and run command appropriately
    if [[ $IS_PRIVILEGED == true ]]; then
        if [[ $IS_ROOT == true ]]; then
            display_info "Running command as root:${CRED} $cmd ${args[@]} ${CE}"
            $cmd ${args[@]}
            _LAST_ELEVATED_CMD_EXIT_CODE=$?
        elif [[ $CAN_SUDO == true ]]; then
            if [[ ( $IS_MAC_USER == true ) && ( $cmd == "brew" ) ]]; then
                display_warning "Running brew install as user:${CGREEN} $cmd ${args[@]} ${CE}"
                $cmd ${args[@]}
                _LAST_ELEVATED_CMD_EXIT_CODE=$?
            else
                display_info "Running command with sudo:${CGREEN} $cmd ${args[@]} ${CE}"
                sudo $cmd ${args[@]}
                _LAST_ELEVATED_CMD_EXIT_CODE=$?
            fi
        else
            display_error "Somehow you are privileged but aren't root and cannot sudo. Exiting."
            exit 1
        fi
    else
        if [[ $REQUIRE_PRIVILEGE == true ]]; then
            display_error "Privileges are required to run this script. Exiting."
            exit 1
        else
            display_warning "Running command without privileges:${CYELLOW} $cmd ${args[@]} ${CE}"
            $cmd ${args[@]}
            _LAST_ELEVATED_CMD_EXIT_CODE=$?
        fi
    fi
}
#============================
#   File Operations
#============================
#TODO:
# safe_copy() {

# }
function safe_move() {
    _tmp_from=$1
    _tmp_to=$2
    display_info "Moving file: ${_tmp_from} to ${_tmp_to}"
    # if [[ -e $_tmp_to ]]; then
        
    # else

    # fi
}
function backup_file() {
    display_info "Backing up file: ${_tmp_to} to ${_tmp_to}.backup"
}
#============================
#   System Package Management 
#============================
function update_system_package() {
    case $OPERATING_SYSTEM in
        Ubuntu | Debian)
            run_elevated_cmd apt update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true
            ;;
        CentOS)
            run_elevated_cmd yum update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true
            ;;
        Darwin)
            display_info "Running command: brew update"
            run_elevated_cmd brew update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true
            ;;
        *) 
            display_error "Unknown system package manager. Exiting."; 
            exit 1
            ;;
    esac
}
function install_system_package() {
    package_name=$1
    command_exists $1 && _result=true || _result=false
    if [[ $_result == true ]];then
        display_success "Package '$package_name' is already installed. Skipping."
        _LAST_ELEVATED_CMD_EXIT_CODE=0
    else
        display_info "Attempting to install system package: '$package_name'."
        if [[ $_SYSTEM_PACKAGE_MANAGER_UPDATED == false ]]; then
            display_info "Updating system packages"
            update_system_package
        fi
        case $OPERATING_SYSTEM in
            Ubuntu | Debian)
                run_elevated_cmd apt install -y $package_name
                if [[ $_LAST_ELEVATED_CMD_EXIT_CODE -eq 0 ]];then
                    display_success "Successfully installed system package '$package_name'."
                else
                    display_error "Something went wrong during package installation. Skipping."
                fi
                ;;
            CentOS)
                run_elevated_cmd yum install -y $package_name
                if [[ $_LAST_ELEVATED_CMD_EXIT_CODE -eq 0 ]];then
                    display_success "Successfully installed system package '$package_name'."
                else
                    display_error "Something went wrong during package installation. Skipping."
                fi
                ;;
            Darwin)
                display_info "Command: brew install -y $package_name"
                run_elevated_cmd brew install $package_name
                if [[ $_LAST_ELEVATED_CMD_EXIT_CODE -eq 0 ]];then
                    display_success "Successfully installed system package '$package_name'."
                else
                    display_error "Something went wrong during package installation. Skipping."
                fi
                ;;
            *) 
                display_error "Unknown system package manager. Exiting."; 
                exit 1
                ;;
        esac  
    fi  
}
# TODO:
# check_system_package() {
    
# }
#============================
#   Display Functions     
#============================
function _display_message() {
    case $OPERATING_SYSTEM in
        Ubuntu | Debian) echo -e "$1 $2 ${CE} ${CWHITE} ${@:3} ${CE}" ;;
        Darwin) echo -e "$1 $2 ${CE} ${CWHITE} ${@:3} ${CE}" ;;
        *) echo -e "$1 $2 ${CE} ${CWHITE} ${@:3} ${CE}" ;;
    esac
}
function display_message() {
    _display_message $CWHITE "     $@"
}
function display_info() {
    _display_message $CBLUE '[*]' "$@"
}
function display_success() {
    _display_message $CGREEN '[+]' "$@"
}
function display_warning() {
    _display_message $CYELLOW '[!]' "$@"
}
function display_error() {
    _display_message $CRED '[-]' "$@"
}
function display_prompt() {
    case $OPERATING_SYSTEM in
        Ubuntu | Debian) echo -ne "$CYELLOW [!] ${CE} ${CWHITE} ${@} ${CE}" ;;
        Darwin) echo -ne "$CYELLOW [!] ${CE} ${CWHITE} ${@} ${CE}" ;;
        *) echo -ne "$CYELLOW [!] ${CE} ${CWHITE} ${@} ${CE}" ;;
    esac
}
function display_bar() {
    CCOLOR=$1:=$CWHITE
    case $OPERATING_SYSTEM in
        Ubuntu | Debian) echo -e "${1}===============================================================================${CE}" ;;
        Darwin) echo -e "${1}===============================================================================${CE}" ;;
        *) echo -e "${1}===============================================================================${CE}" ;;
    esac
}
function display_array() {
    local _raw_array=($1)
    display_info "Displaying Array:"
    for element in ${_raw_array[@]}; do
        display_message "\tElement: ${element}"
    done 
}
function prompt_user {
    ! check_bash_version && return 1
    # handle associative arguments
    declare -A _args
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
    # debug messaging
    if [[ $DEBUG == true ]];then
        display_info "Message: $_message"
        display_info "Default Action: $_default_action"
        display_info "Warning Message: $_warning_message"
        display_info "Success Message: $_success_message"
        display_info "Failure Message: $_failure_message"
        display_info "Exit on Failure: $_exit_on_failure"
        display_info "Error Message: $_error_message"
    fi
    # Prompt user for program execution.
    [[ ! -z "$_warning_message" ]] && display_warning "$_warning_message"
    display_prompt "$_message"
    read _user_response
    # Assign default action
    local user_response=${_user_response:-$_default_action}
    case $user_response in
        [yY][eE][sS]|[yY])  [[ ! -z "$_success_message" ]] && display_success "$_success_message"
            return 0 ;;
        [nN][oO]|[nN])  [[ ! -z "$_failure_message" ]] && display_warning "$_failure_message"
            [[ $_exit_on_failure == true ]] && exit 1
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
function add_terminal_colors() {
    # Reset Color
    CE="\033[0m"
    # Text: Common Color Names
    CT="\033[38;5;"
    CRED="${CT}9m"
    CGREEN="${CT}28m"
    CBLUE="${CT}27m"
    CORANGE="${CT}202m"
    CYELLOW="${CT}226m"
    CPURPLE="${CT}53m"
    CWHITE="${CT}255m"
    # Text: All Hex Values
    for HEX in {0..255};do eval "C$HEX"="\\\033[38\;5\;${HEX}m";done
    # Background: Common Color Names
    CB="\033[48;5;"
    CBRED="${CB}9m"
    CBGREEN="${CB}46m"
    CBBLUE="${CB}27m"
    CBORANGE="${CB}202m"
    CBYELLOW="${CB}226m"
    CBPURPLE="${CB}53m"
    # Background: All Hex Values
    for HEX in {0..255};do eval "CB${HEX}"="\\\033[48\;5\;${HEX}m";done
}
function sigint_handler {
    echo
    display_error "Signal Interrupt was received, CTRL + C."
    display_prompt "Do you wish to continue with the program [Y/n]: "
        read user_response
        # Default to Yes
        user_response=${user_response:-"Y"}
        case $user_response in
            [yY][eE][sS]|[yY])
                display_info "Attempting to continue with program execution. There might be errors."
                ;;
            [nN][oO]|[nN])
                display_warning "User chose to not continue. Exiting."
                exit 1
                ;;
            *)
                display_error "Invalid option. Exiting."
                exit 1
                ;;
        esac
}
function exit_handler {
    display_info "Program exiting. Good bye."
}
function check_bash_version {
    local _primary_version=$(echo $BASH_VERSION | grep -Eo '^[0-9]')
    local _secondary_version=$(echo $BASH_VERSION | grep -Eo '^[0-9]\.[0-9]' | cut -f2 -d\.)
    [[ $DEBUG == true ]] && echo "Bash Version: ${_primary_version}.${_secondary_version}"
    # If 4.X, check if it's 4.4 or higher, if 4.4+ then skip.
    [[ "$_primary_version" -eq 4 ]] && [[ "$_secondary_version" -gt 3 ]] && return 0
    # if 5.x+ then skip.
    [[ "$_primary_version" -gt 4 ]] && return 0
    # Return false is lower version than 4.4
    return 1
}
#============================
#   Main Execution / Initialization
#============================
[[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && echo "Script requires bash 4.4+" && exit 1
add_terminal_colors
check_operating_system
check_privileges
# main "$@"