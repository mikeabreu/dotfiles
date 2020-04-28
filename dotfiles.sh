#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
#============================
#   Configurable Variables
#============================
CREATE_TMUX_SESSION=true
DEBUG=false
VERBOSE=false
#============================
#   Global Variables
#============================
REQUIRE_BASH_4_4=false
REQUIRE_PRIVILEGE=true
INSTALL_DEPENDENCIES=true
PROFILE_FILENAME=${PROFILE_FILENAME:-"profiles/default.json"}
DOTFILES="${HOME}/dotfiles"
DOTFILES_HOME="${DOTFILES}/_home"
DOTFILES_ETC="${DOTFILES}/_etc"
DOTFILES_BIN="${DOTFILES}/_bin"
DOTFILES_LOGS="${DOTFILES}/_logs"
LIBCORE_LOGS="$DOTFILES_LOGS"
#============================
#   Imports
#============================
[[ -r "lib/lib-core.sh" ]] && source "lib/lib-core.sh" || (echo "Missing lib-core.sh" && exit 1)
[[ -r "lib/lib-dotfiles.sh" ]] && source "lib/lib-dotfiles.sh" || (echo "Missing lib-dotfiles.sh" && exit 1)
[[ -r "lib/lib-installers.sh" ]] && source "lib/lib-installers.sh" || (echo "Missing lib-installers.sh" && exit 1)
#============================
#   Help Message
#============================
help_message() {
    display_bar
    display_message """
    dotfiles - Mike Abreu
    This program will configure your terminal environment and maintain it.

    Options:
    -h          Display this help message.
    -p          Load a profile from json file.
    -t          Skip creating and attaching to a tmux session.
    -d          Skip installing dotfile dependencies.
    -v          Enable verbose messaging.

    Examples:
    ./dotfiles.sh
    ./dotfiles.sh -vt
    ./dotfiles.sh -p profile-default.json
    ./dotfiles.sh -vt -p profile-default.json
    """
}
#============================
#   Arguments
#============================
function handle_arguments {
    # Arg: -p "path/to/profile.json" | Load profile
    # Arg: -h | Help Message
    # Arg: -t | Skip attaching to tmux
    # Arg: -d | Skip installing dependencies
    # Arg: -v | Enable Verbose
    while getopts ":p:htdv" opt;do
        case $opt in
            p)  PROFILE_FILENAME="$OPTARG" ;;
            h)  help_message && display_bar && exit 1 ;;
            t)  CREATE_TMUX_SESSION=false ;;
            d)  INSTALL_DEPENDENCIES=false ;;
            v)  VERBOSE=true ;;
            \?) display_error "Invalid option: -$OPTARG. Exiting." >&2; exit 1 ;;
            :)  display_error "Option -$OPTARG requires an argument. Exiting." >&2; exit 1 ;;
        esac
    done
}
#============================
#   Main Function
#============================
function main {
    # Handle Arguments
    handle_arguments "$@"
    if [[ $INSTALL_DEPENDENCIES == true ]];then
        # Welcome Message
        help_message
        display_bar
        display_header "${CGREEN}OPERATING_SYSTEM:${CE} ${CWHITE} ${OPERATING_SYSTEM}"
        display_header "${CGREEN}OPERATING_SYSTEM_VERSION:${CE} ${CWHITE} ${OPERATING_SYSTEM_VERSION}"
        # Prompt user for program execution.
        display_warning "This program will install packages and change your terminal configuration."
        display_prompt "Do you wish to continue with the program [Y/n]: "
        # Do manual user prompt because we haven't installed bash 4.4+ on macOS yet
        read user_response
        user_response=${user_response:-"Y"}
        case $user_response in
            [yY][eE][sS]|[yY]) display_info "Continuing with program execution." ;;
            [nN][oO]|[nN]) display_warning "User chose to not continue. Exiting." && exit 1 ;;
            *) display_error "Invalid option. Exiting." && exit 1 ;;
        esac
        ! $IS_PRIVILEGED && display_info "Determining user privileges and sudo access." && check_privileges
        # Install dependencies for dotfiles to operate
        display_bar
        display_header "Installing dotfile dependencies"
        [[ $OPERATING_SYSTEM == 'Darwin' ]] && install_brew
        [[ $OPERATING_SYSTEM == 'Darwin' ]] && install_brew_bash
        [[ $OPERATING_SYSTEM == 'Darwin' ]] && install_brew_coreutils
        install_system_package "jq"
        install_system_package "stow"
        install_system_package "tmux"
        install_system_package "git"
    fi
    display_bar
    if [[ $CREATE_TMUX_SESSION == true ]];then
        # Load tmux
        ! tmux list-sessions &>/dev/null | grep "dotfiles" &>/dev/null && 
            display_header "Tmux: Starting new-session 'dotfiles'" &&
            tmux new-session -d -s dotfiles
        prompt_user message="About to connect to tmux, are you ready? [Y/n]: " \
            failure_message="You were not ready, run with -t to skip tmux." \
            success_message="" error_message="" warning_message=""
        display_header "Tmux: Attaching to session 'dotfiles'"
        tmux send-keys "./dotfiles.sh -td" Enter
        tmux attach-session -t dotfiles &>/dev/null
        display_warning "Tmux: Continuing execution in tmux session. Exiting."
        exit 0
    fi
    # Check if privileged. Needed because of potential skips for dependency and tmux
    ! $IS_PRIVILEGED && display_info "Determining user privileges and sudo access." && check_privileges
    # Load the profile and display to user before continuing
    load_profile $PROFILE_FILENAME
    # Install and configure the profile to the system
    install_profile $PROFILE_FILENAME
    # Display a status of all actions performed and their success/failure
    # TODO: 
}
#============================
#   Main Execution
#============================
main "$@"