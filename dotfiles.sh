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
INSTALL_DEPENDENCIES=true
PROFILE_FILENAME=${PROFILE_FILENAME:-"profiles/default.json"}
DOTFILES="${HOME}/dotfiles"
DOTFILES_LOGS="${DOTFILES}/_logs" && LIBCORE_LOGS="$DOTFILES_LOGS"
#============================
#   Imports
#============================
[[ -r "lib/lib-core.sh" ]] && { source "lib/lib-core.sh" || { 
        echo "DOTFILES: Failed to load lib-core.sh, run with debug true for details"; exit 1; }
} || {  echo "DOTFILES: Missing lib-core.sh, run with debug true for details"; exit 1; }
[[ -r "lib/lib-installers.sh" ]] && { source "lib/lib-installers.sh" || { 
        echo "DOTFILES: Failed to load lib-installers.sh, run with debug true for details"; exit 1; } 
} || {  echo "DOTFILES: Missing lib-installers.sh, run with debug '-D' true for details"; exit 1; }
#============================
#   Help Message
#============================
function help_message {
    display_bar
    display_message """
    dotfiles - Mike Abreu
    This program will configure your terminal environment and maintain it.

    Options:
    -h                          Display this help message.
    -p \"path/to/profile\"        Load a profile from json file.
    -t                          Skip creating and attaching to a tmux session.
    -s                          Skip installing dotfile dependencies.
    -d                          Debug messaging
    -v                          Enable verbose messaging.

    Examples:
    ./dotfiles.sh
    ./dotfiles.sh -vt
    ./dotfiles.sh -p profile-default.json
    ./dotfiles.sh -vtdp profile-default.json
    """
}
#============================
#   Arguments
#============================
function handle_arguments {
    # Arg: -p "path/to/profile.json" | Load profile
    # Arg: -h | Help Message
    # Arg: -t | Skip attaching to tmux
    # Arg: -s | Skip installing dependencies
    # Arg: -d | Debug messaging
    # Arg: -v | Enable Verbose
    while getopts ":p:htsdv" opt;do
        case $opt in
            p)  PROFILE_FILENAME="$OPTARG" ;;
            h)  help_message && display_bar && exit 1 ;;
            t)  CREATE_TMUX_SESSION=false ;;
            s)  INSTALL_DEPENDENCIES=false ;;
            d)  DEBUG=true ;;
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
    REQUIRE_PRIVILEGE=true && check_privileges
    if [[ $INSTALL_DEPENDENCIES == true ]];then
        # Welcome Message
        help_message
        display_bar
        display_info "${CGREEN}OPERATING_SYSTEM:${CE} ${CWHITE} ${OPERATING_SYSTEM}"
        display_info "${CGREEN}OPERATING_SYSTEM_VERSION:${CE} ${CWHITE} ${OPERATING_SYSTEM_VERSION}"
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
        display_title "Installing dotfile dependencies"
        [[ $OPERATING_SYSTEM == 'Darwin' ]] && {
            install_brew
            install_brew_bash
            install_brew_coreutils
        }
        install_system_package "jq"
        install_system_package "stow"
        install_system_package "tmux"
        install_system_package "git"
    fi
    [[ -r "lib/lib-dotfiles.sh" ]] && { source "lib/lib-dotfiles.sh" || { 
            echo "DOTFILES: Failed to load lib-dotfiles.sh, run with debug true for details"; exit 1; }
    } || {  echo "DOTFILES: Missing lib-dotfiles.sh, run with debug true for details"; exit 1; }
    display_bar
    if [[ $CREATE_TMUX_SESSION == true ]];then
        # Load tmux
        ! tmux list-sessions &>/dev/null | grep "dotfiles" &>/dev/null && {
            display_title "Tmux: Starting new-session 'dotfiles'"
            tmux new-session -d -s dotfiles
        }
        prompt_user message="About to connect to tmux, are you ready? [Y/n]: " \
            failure_message="You were not ready, run with -t to skip tmux." \
            success_message="" error_message="" warning_message=""
        display_title "Tmux: Attaching to session 'dotfiles'"
        tmux send-keys "./dotfiles.sh -ts" Enter
        tmux attach-session -t dotfiles &>/dev/null
        display_warning "Tmux: Continuing execution in tmux session. Exiting."
        exit 0
    fi
    # Check if privileged. Needed because of potential skips for dependency and tmux
    ! $IS_PRIVILEGED && display_info "Determining user privileges and sudo access." && check_privileges
    # Load the profile and display to user before continuing
    load_profile "$PROFILE_FILENAME"
    # Install and configure the profile to the system
    install_profile "$PROFILE_FILENAME"
    
    display_info "Finished setting up shell. Starting new shell. Restart terminal to start fresh."
    $(which ${DOTFILES_PROFILE[SHELL]})
}
#============================
#   Main Execution
#============================
echo -e "\n\n\n\nRuntime Date: $(date)" >> "${DOTFILES_LOGS}/dotfiles_log"
main "$@" | tee -a "${DOTFILES_LOGS}/dotfiles_log"