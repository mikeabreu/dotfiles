#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
# Description: This library file contains lots of useful bash functions that I've
#   created previously. It's useful to include this lib-core file at the top of a
#   new script you are creating. It brings in lots of tested functionality.
#========================================================
#   Dependency Check
#========================================================
# Prevent duplicate sourcing
[[ $_LOADED_LIB_CORE == true ]] && {
    [[ $DEBUG == true ]] && display_debug "Skipping: Duplicate source attempt on lib-core.sh."
    return 0
}
#========================================================
#   Script Variables
#========================================================
#   Assign these before sourcing this file to overwrite defaults
declare _LIB_SETUP_ACTIONS=${_LIB_SETUP_ACTIONS:-true}
declare REQUIRE_BASH_4_4=${REQUIRE_BASH_4_4:-true}
declare REQUIRE_PRIVILEGE=${REQUIRE_PRIVILEGE:-false}
declare ENABLE_TRAP_HANDLERS=${ENABLE_TRAP_HANDLERS:-true}
declare VERBOSE=${VERBOSE:-false}
declare DEBUG=${DEBUG:-false}
declare LIBCORE_LOGS=${LIBCORE_LOGS:-""}
#========================================================
#   Global Variables
#========================================================
declare OPERATING_SYSTEM=${OPERATING_SYSTEM:-"Unknown"}
declare OPERATING_SYSTEM_VERSION=${OPERATING_SYSTEM_VERSION:-"Unknown"}
declare IS_PRIVILEGED=false
declare IS_ROOT=false
declare HAS_SUDO=false
declare CAN_SUDO=false
declare _LOADED_LIB_CORE=true
#========================================================
#   Core Functions
#========================================================
function command_exists {
    which "$1" &>/dev/null || command -v "$1" &>/dev/null
}
function check_privileges {
    [[ $REQUIRE_PRIVILEGE == false ]] && return 0
    [[ -n $SUDO_USER ]] && { display_warning "Script was run with sudo."; }
    [[ $EUID -eq 0 ]] && { IS_ROOT=true; IS_PRIVILEGED=true; }
    command_exists sudo && {
        # Success: sudo exists
        HAS_SUDO=true
        sudo -S true </dev/null 2>/dev/null && {
            # Success: user can sudo and is privileged
            CAN_SUDO=true && IS_PRIVILEGED=true
        } || {
            # Failure: check if user can sudo and if they have privilege
            command_exists timeout && {
                # Use timeout
                display_warning "Testing user for 'sudo' rights. Exiting after 1 minute."
                timeout --foreground 1m sudo -v 2>/dev/null && CAN_SUDO=true && IS_PRIVILEGED=true
            } || {
                # Dont use timeout
                display_warning "Testing user for 'sudo' rights. Exiting after 5 minute."
                sudo -v 2>/dev/null && CAN_SUDO=true && IS_PRIVILEGED=true
            }
        }
    }
    [[ $DEBUG == true ]] && {
        display_debug "Found the following privileges for current user:"
        display_debug "\tIS_PRIVILEGED: ${IS_PRIVILEGED}"
        display_debug "\tIS_ROOT: ${IS_ROOT}"
        display_debug "\tHAS_SUDO: ${HAS_SUDO}"
        display_debug "\tCAN_SUDO: ${CAN_SUDO}"
    }
    # Return success if privileged
    [[ $IS_PRIVILEGED == true ]] && return 0
    [[ $REQUIRE_PRIVILEGE == true ]] && [[ $IS_PRIVILEGED == false ]] && {
        # If privilege is required but user isnt privileged, exit.
        display_error "Privileges are required to run this script. Exiting."
        exit 1
    }
    # Return false if not privileged
    return 1
}
function check_operating_system {
    # Try to determine from '/etc/centos-release'
    [[ -f /etc/centos-release ]] && {
        OPERATING_SYSTEM=$(cat /etc/centos-release | awk '{print $1}')
        OPERATING_SYSTEM_VERSION=$(cat /etc/centos-release | awk '{print $4}' | awk -F . '{print $1}')
        return 0
    }
    # Try to determine from '/etc/issue'
    [[ -f /etc/issue ]] && {
        OPERATING_SYSTEM=$(cat /etc/issue | awk '{print $1}')
        [[ $OPERATING_SYSTEM == 'Ubuntu' ]] && 
            OPERATING_SYSTEM_VERSION=$(cat /etc/issue | awk '{print $2}' | awk -F . '{print $1}')
        [[ $OPERATING_SYSTEM == 'Debian' ]] &&
            OPERATING_SYSTEM_VERSION=$(cat /etc/issue | awk '{print $3}' | awk -F . '{print $1}')
    }
    # Try to determine from uname
    [[ $OPERATING_SYSTEM == 'Unknown' ]] && 
        OPERATING_SYSTEM=$(uname -a | awk '{print $1}')
    [[ $OPERATING_SYSTEM_VERSION == 'Unknown' ]] && 
        OPERATING_SYSTEM_VERSION=$(uname -a | awk '{print $3}' | awk -F . '{print $1}')
    # Debug Messages
    [[ $DEBUG == true ]] && {
        [[ $OPERATING_SYSTEM_VERSION == 'Unknown' ]] && display_debug "Unknown Operating System. Warn."
        [[ $OPERATING_SYSTEM_VERSION == 'Unknown' ]] && display_debug "Unknown Operating System Version. Warn."
    }
    return 0
}
function run_elevated_cmd {
    # Handle arguments being passed in
    raw_arguments=("$@")
    args=()
    for index in "${!raw_arguments[@]}";do
        [[ $index -eq 0 ]] && cmd=${raw_arguments[$index]}
        [[ $index -ne 0 ]] && args+=( ${raw_arguments[$index]} )
    done
    # Determine privileges and run command appropriately
    [[ $IS_PRIVILEGED != true ]] && return 1
    [[ $IS_ROOT == true ]] && {
        display_info "Running command as root:" "$cmd ${args[@]}"
        $cmd ${args[@]}
        return "$?"
    }
    [[ $CAN_SUDO == true ]] && {
        if [[ $OPERATING_SYSTEM == "Darwin" ]] && [[ $cmd == "brew" ]]; then
            display_warning "Running brew install as user:" "$cmd ${args[@]}"
            $cmd ${args[@]}
            return "$?"
        else
            display_info "Running command with sudo:" "$cmd ${args[@]}"
            sudo $cmd ${args[@]}
            return "$?"
        fi
    }
    display_warning "Running command without privileges:" "$cmd ${args[@]}"
    $cmd ${args[@]}
    return "$?"
}
#========================================================
#   Display Functions     
#========================================================
function _display_message {
    # $1 = Color (i.e. $CRED, $CGREEN, etc.)
    # $2 = Symbol (i.e. [+], [-], etc.)
    # $3 = Message
    echo -e "${1}${2}${CE} ${@:3} ${CE}"
}
function newline {
    echo "" && return 0
}
function display_message {
    _display_message $CWHITE "$@"
}
function display_title {
    _display_message $CLPINK "[~] $1" "${@:2}"
}
function display_info {
    _display_message $CLBLUE "[*] $1" "${@:2}"
}
function display_success {
    _display_message $CLGREEN "[+] $1" "${@:2}"
}
function display_warning {
    _display_message $CYELLOW "[!] $1" "${@:2}"
}
function display_error {
    _display_message $CLRED "[-] $1" "${@:2}"
}
function display_debug {
    [[ -z "$@" ]] && echo -ne "$CPINK [~]    DEBUG OUTPUT:${CE} "
    [[ -n "$@" ]] && _display_message $CPINK '[~]    DEBUG: ' "$@"
}
function display_prompt {
    echo -ne "$CYELLOW [!]${CE}${CWHITE} ${@} ${CE}"
}
function display_bar {
    CCOLOR=${1:-$CGRAY}
    echo -e "${CCOLOR}===============================================================================${CE}"
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
    local -A args
    for arg in "$@";do
        local key="$(echo "$arg" | cut -f1 -d=)"
        local value="$(echo "$arg" | cut -f2 -d=)"
        args+=([$key]="$value")
    done
    # assign local variables from associative array
    local message="${args[message]:-"Do you wish to continue with the program [Y/n]: "}"
    local default_action="${args[default_action]:-"Y"}"
    local warning_message="${args[warning_message]:-""}"
    local success_message="${args[success_message]:-""}"
    local failure_message="${args[failure_message]:-""}"
    local exit_on_failure="${args[exit_on_failure]:-true}"
    local error_message="${args[error_message]:-""}"
    # Prompt user for program execution.
    [[ -n "$warning_message" ]] && display_warning "$warning_message"
    display_prompt "$message"
    read _user_response
    # Assign default action
    local user_response=${_user_response:-$default_action}
    case $user_response in
        [yY][eE][sS]|[yY])  [[ -n "$success_message" ]] && display_success "$success_message"; return 0 ;;
        [nN][oO]|[nN])      [[ $exit_on_failure == true ]] && [[ -n "$failure_message" ]] && {
                                display_error "$failure_message"
                                exit 1
                            }
                            [[ -n "$failure_message" ]] && display_warning "$failure_message"
                            return 1 ;;
        *)  [[ -n "$error_message" ]] && display_error "$error_message"; exit 1 ;;
    esac
}
#========================================================
#   Misc Functions  
#========================================================
function add_terminal_colors {
    # Reset Color
    CE="\033[0m"
    # Text: Common Color Names
    CT="\033[38;5;"
    CRED="${CT}9m"
    CGREEN="${CT}28m"
    CBLUE="${CT}27m"
    CTEAL="${CT}50m"
    CORANGE="${CT}202m"
    CYELLOW="${CT}226m"
    CPINK="${CT}13m"
    CPURPLE="${CT}63m"

    CLRED="${CT}196m"
    CLGREEN="${CT}46m"
    CLBLUE="${CT}45m"
    CLPINK="${CT}171m"

    CGRAY="${CT}240m"
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
function remove_color {
    sed -e 's/\[[0-9]\{2\}[;][0-9][;][0-9]\{1,3\}m//g' -e 's/\[0m//g' -e 's///g'
}
function check_bash_version {
    # [[ $DEBUG == true ]] && display_debug "Bash Version: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
    # If 4.X, check if it's 4.4 or higher, if 4.4+ then skip.
    [[ "${BASH_VERSINFO[0]}" -eq 4 ]] && [[ "${BASH_VERSINFO[1]}" -gt 3 ]] && return 0
    # if 5.x+ then skip.
    [[ "${BASH_VERSINFO[0]}" -gt 4 ]] && return 0
    # Return false if lower version than 4.4
    return 1
}
function logfile {
    local file="$1"
    while true ; do
        [[ $OPERATING_SYSTEM == "Darwin" ]] && {
            # macOS
            read -r -s -t 0.1 -s holder
        } || {
            # Default
            read -r -s -t 0.1 -s holder
        }
        local result="$?"
        local line="$holder"
        [[ "$result" -eq 0 || "$result" -eq 142  ]] && {
            [[ -n "$line" ]] && {
                # Display the line to stdout with color.
                [[ "$result" -eq 0   ]] && echo -e "$line"
                [[ "$result" -eq 142 ]] && echo -ne "$line"
                # Log the information to the logfile without color.
                echo "$line" | remove_color >> $file
            }
            [[ $FULL_DEBUG == true ]] && display_debug "Logfile result:[${result}]"
            continue
        }
        [[ $FULL_DEBUG == true ]] && display_debug "Logfile result:[${result}]"
        break
    done
}
#========================================================
#   Trap Handlers
#========================================================
function sigint_handler {
    echo
    prompt_user message="Do you wish to continue with the program [y/N]: " \
        warning_message="Signal Interrupt was received, CTRL + C." \
        success_message="Attempting to continue with program execution. There might be errors." \
        failure_message="User exited the program." \
          error_message="Invalid option" \
         default_action="N"
}
function exit_handler {
    local result="$?"
    [[ $result -eq 0 ]] && [[ $VERBOSE == true ]] && display_success "Program is exiting succesfully. Good bye."
    [[ $result -ne 0 ]] && [[ $VERBOSE == true ]] && display_error   "Program exited with an error. Good bye."
}
#========================================================
#   Main Execution / Initialization
#========================================================
add_terminal_colors
[[ $DEBUG == true ]] && display_debug "LIB-CORE: Loaded lib-core.sh file"
[[ $_LIB_SETUP_ACTIONS == true ]] && {
    [[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && {
        [[ $DEBUG == true ]] && display_debug "lib-core.sh requires bash 4.4+"
        return 1
    }
    [[ $ENABLE_TRAP_HANDLERS == true ]] && trap sigint_handler SIGINT
    [[ $ENABLE_TRAP_HANDLERS == true ]] && trap exit_handler EXIT
    [[ -n "$LIBCORE_LOGS" ]] && {
        # if logs folder isnt ""
        [[ ! -d "$LIBCORE_LOGS" ]] && {
            # if logs folder isn't a directory
            [[ -e "$LIBCORE_LOGS" ]] && {
                # and the logs folder exists, its a blocking file
                display_warning "Removing blocking file for: $LIBCORE_LOGS"
                backup_file "$LIBCORE_LOGS"
                rm -fr "$LIBCORE_LOGS"
            }
            # Make the logs folder
            display_info "Making log folder:" "$LIBCORE_LOGS"
            mkdir -p "$LIBCORE_LOGS"
        }
    }
    check_operating_system
    check_privileges
}
return 0
