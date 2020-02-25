#!/usr/bin/env bash
#
# Library of bash functions and configuration variables.

# Global Variables
OPERATING_SYSTEM="Unknown"
OPERATING_SYSTEM_VERSION="Unknown"
SYSTEM_PACKAGE_MANAGER_UPDATED="False"

# Test Main
# main() {
    # display_bar
    # check_operating_system
    # # Determine operating system and version
    # display_bar
    # display_info "OPERATING_SYSTEM: ${OPERATING_SYSTEM}"
    # display_info "OPERATING_SYSTEM_VERSION: ${OPERATING_SYSTEM_VERSION}"
    # install_system_package jq
# }

# Functions
check_operating_system() {
    if [[ -e /etc/centos-release ]];then
        # CentOS
        OPERATING_SYSTEM=$(cat /etc/centos-release | awk '{print $1}')
        OPERATING_SYSTEM_VERSION=$(cat /etc/centos-release | awk '{print $4}' | awk -F . '{print $1}')
    elif [[ -e /etc/issue ]];then
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
update_system_package() {
    case $OPERATING_SYSTEM in
        Ubuntu | Debian)
            display_info "Command: sudo apt update"
            sudo apt update && SYSTEM_PACKAGE_MANAGER_UPDATED=True
            ;;
        CentOS)
            display_info "Command: sudo yum update"
            sudo yum update && SYSTEM_PACKAGE_MANAGER_UPDATED=True
            ;;
        Darwin)
            display_info "Command: brew update"
            brew update && SYSTEM_PACKAGE_MANAGER_UPDATED=True
            ;;
        *) 
            display_error "Unknown system package manager. Exiting."; 
            exit 1
            ;;
    esac
}
install_system_package() {
    which $1 >/dev/null
    is_installed=$?
    if [[ is_installed -eq 0 ]];then
        display_success "Package '$1' is already installed. Skipping."
    else
        display_info "Attempting to install system package: '$1'."
        if [[ $SYSTEM_PACKAGE_MANAGER_UPDATED == 'False' ]]; then
            display_info "Updating system packages"
            update_system_package
        fi
        case $OPERATING_SYSTEM in
            Ubuntu | Debian)
                display_info "Command: sudo apt install -y $1"
                sudo apt install -y $1 \
                    && display_success "Successfully installed system package '$1'."
                ;;
            CentOS)
                display_info "Command: sudo yum install -y $1"
                sudo yum install -y $1 \
                    && display_success "Successfully installed system package '$1'."
                ;;
            Darwin)
                display_info "Command: brew install -y $1"
                brew install $1 \
                    && display_success "Successfully installed system package '$1'."
                ;;
            *) 
                display_error "Unknown system package manager. Exiting."; 
                exit 1
                ;;
        esac  
    fi  
}

_display_message() {
    case $OPERATING_SYSTEM in
        Ubuntu | Debian) echo -e "$1 $2 ${CE} ${@:3} ${CE}" ;;
        Darwin) echo "$1 $2 ${CE} ${@:3} ${CE}" ;;
        *) echo "$1 $2 ${CE} ${@:3} ${CE}" ;;
    esac
}
display_message() {
    _display_message $CWHITE "     $@"
}
display_info() {
    _display_message $CBLUE '[*]' $@
}
display_success() {
    _display_message $CGREEN '[+]' $@
}
display_warning() {
    _display_message $CYELLOW '[!]' $@
}
display_error() {
    _display_message $CRED '[-]' $@
}
display_bar() {
    CCOLOR=$1:=$CWHITE
    echo "${1}========================================================================================${CE}"
}
add_terminal_colors() {
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
add_terminal_colors
# Testing Main
# main "$@"