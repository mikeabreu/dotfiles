#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
#============================
#   Imports
#============================
REQUIRE_BASH_4_4=false
[[ -r "lib/lib-core.sh" ]] && source "lib/lib-core.sh" || exit 1
[[ -r "lib/lib-dotfiles.sh" ]] && source "lib/lib-dotfiles.sh" || exit 1

#============================
#   Help Message
#============================
help_message() {
    display_bar
    display_message """
    dotfiles - Mike Abreu
    This program will configure your terminal environment and maintain it.

    Options:
    -p          Load a profile from json file.
    -t          Skip creating and attaching to a tmux session.
    -d          Skip installing dotfile dependencies.

    Examples:
    ./dotfiles.sh
    ./dotfiles.sh -p profile-default.json
    """
}
#============================
#   Configurable Variables
#============================
DEBUG=false
VERBOSE=false
CREATE_TMUX_SESSION=true
#============================
#   Global Variables
#============================
REQUIRE_PRIVILEGE=true
INSTALL_DEPENDENCIES=true
PROFILE_FILENAME=${PROFILE_FILENAME:-"profiles/default.json"}
DOTFILES="${HOME}/dotfiles"
DOTFILES_HOME="${DOTFILES}/_home"
DOTFILES_ETC="${DOTFILES}/_etc"
DOTFILES_BIN="${DOTFILES}/_bin"
DOTFILES_LOGS="${DOTFILES}/_logs"

#============================
#   Main Function Execution
#============================
function main {
    # Handle Traps
    trap sigint_handler SIGINT
    trap exit_handler EXIT

    # Handle Arguments
    handle_arguments "$@"

    if [[ $INSTALL_DEPENDENCIES == true ]];then
        # Welcome Message
        help_message
        display_bar
        display_info "${CGREEN}OPERATING_SYSTEM:${CE} ${CWHITE} ${OPERATING_SYSTEM}"
        display_info "${CGREEN}OPERATING_SYSTEM_VERSION:${CE} ${CWHITE} ${OPERATING_SYSTEM_VERSION}"

        # Prompt user for program execution.
        display_warning "This program will install packages and change your terminal configuration."
        display_prompt "Do you wish to continue with the program [Y/n]: "
        # Do manual user prompt because we haven't installed bash 4.4+ on macOS
        read user_response
        # Default to Yes
        user_response=${user_response:-"Y"}
        case $user_response in
            [yY][eE][sS]|[yY]) display_info "Continuing with program execution." ;;
            [nN][oO]|[nN]) display_warning "User chose to not continue. Exiting." && exit 1 ;;
            *) display_error "Invalid option. Exiting." && exit 1 ;;
        esac
        ! $IS_PRIVILEGED && display_info "Determining user privileges and sudo access." && check_privileges

        # Install dependencies for dotfiles to operate
        display_bar
        display_info "Installing dotfile dependencies"
        [[ $OPERATING_SYSTEM == 'Darwin' ]] && install_brew
        [[ $OPERATING_SYSTEM == 'Darwin' ]] && install_bash
        [[ $OPERATING_SYSTEM == 'Darwin' ]] && install_timeout
        install_system_package "jq"
        install_system_package "stow"
        install_system_package "tmux"
        install_system_package "git"
    fi

    display_bar
    if [[ $CREATE_TMUX_SESSION == true ]];then
        # Load tmux
        tmux list-sessions | grep "dotfiles" >/dev/null
        if [[ $? -eq 1 ]]; then
            display_info "Tmux: Starting new-session 'dotfiles'"
            tmux new-session -d -s dotfiles
        fi
        prompt_user message="About to connect to tmux, are you ready? [Y/n]: " \
            failure_message="You were not ready, run with -t to skip tmux." \
            success_message="" error_message="" warning_message=""
        display_info "Tmux: Attaching to session 'dotfiles'"
        tmux send-keys "./dotfiles.sh -td" Enter
        tmux attach-session -t dotfiles
        display_warning "Tmux: Continuing execution in tmux session. Exiting."
        exit 0
    fi
    ! $IS_PRIVILEGED && display_info "Determining user privileges and sudo access." && check_privileges
    # Validate Profile, Display Profile, Prompt User to Continue
    load_profile $PROFILE_FILENAME
    # If still executing, user approved. Install Profile
    install_profile $PROFILE_FILENAME
}

#============================
#   Helper Functions
#============================
function handle_arguments {
    while getopts ":p:htdv" opt;do
        case $opt in
            h)  help_message
                display_bar
                exit 1
                ;;
            d)  INSTALL_DEPENDENCIES=false
                ;;
            t)  CREATE_TMUX_SESSION=false
                ;;
            p)  PROFILE_FILENAME="$OPTARG"
                ;;
            v)  VERBOSE=true
                ;;
            \?) display_error "Invalid option: -$OPTARG. Exiting." >&2
                exit 1
                ;;
            :)  display_error "Option -$OPTARG requires an argument. Exiting." >&2
                exit 1
                ;;
        esac
    done
}
function install_brew {
    command_exists brew && _result=true || _result=false
    if [[ $_result == true ]];then
        display_success "Package 'brew' is already installed. Skipping."
    else
        display_info "Installing package manager 'brew' on the system."
        # /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" &&
            display_success "Package Manager brew has been successfully installed."
    fi
}
function install_bash {
    check_bash_version && display_success "Package 'bash' is already 4.4 of higher. Skipping." && return 0
    display_info "Installing package 'bash' with brew."
    brew install bash
    return $?
}
function install_timeout {
    command_exists timeout && _result=true || _result=false
    if [[ $_result == true ]];then
        display_success "Package 'coreutils' is already installed. Skipping."
    else
        # 'coreutils' is required for the use of 'timeout' in check_privileges. Mac OS Only
        display_info "Installing package 'coreutils' with brew."
        brew install coreutils
        # Check privileges again to pickup non-sudo use of brew
        check_privileges
    fi
}
#============================
#   Main Execution
#============================
main "$@"