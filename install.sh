#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
# Traps
trap error_handler ERR
trap exit_handler EXIT

# Imports
source lib-core.sh
source lib-config.sh

# Help Message
help_message() {
    display_bar
    display_message """
    dotfiles - Mike Abreu
    This script will configure your terminal environment.

    Options:
    -p          Load a profile from json file.
    -t          Skip creating and attaching to a tmux session.
    -d          Skip installing dotfile dependencies.

    Examples:
    ./install.sh
    ./install.sh -p profile-default.json
    """
}

# Global Variables
INSTALL_DEPENDENCIES="True"
CREATE_TMUX_SESSION="True"
PROFILE_FILENAME=${PROFILE_FILENAME:-"None"}

# Main
main() {
    # Determine operating system and version
    check_operating_system
    handle_arguments "$@"

    if [[ $INSTALL_DEPENDENCIES == "True" ]];then
        # Welcome Prompt
        help_message
        display_bar
        display_info "OPERATING_SYSTEM: ${OPERATING_SYSTEM}"
        display_info "OPERATING_SYSTEM_VERSION: ${OPERATING_SYSTEM_VERSION}"

        # Install dependencies for dotfiles to operate
        display_bar
        display_info "Installing dotfile dependencies"
        if [[ $OPERATING_SYSTEM == 'Darwin' ]];then
            install_brew
        fi
        install_system_package "jq"
        install_system_package "stow"
        install_system_package "tmux"
    fi

    display_bar
    if [[ $CREATE_TMUX_SESSION == "True" ]];then
        # Load tmux
        tmux list-sessions | grep "dotfiles" >/dev/null
        if [[ $? -eq 1 ]]; then
            display_info "Tmux: Starting new-session 'dotfiles'"
            tmux new-session -d -s dotfiles
        fi
        display_info "Tmux: Attaching to session 'dotfiles'"
        if [[ $OPERATING_SYSTEM == 'Darwin' ]];then
            tmux send-keys "sh ./install.sh -td" Enter
        else
            tmux send-keys "./install.sh -td" Enter
        fi
        tmux attach-session -t dotfiles
        display_warning "Tmux: Continuing execution in tmux session. Exiting."
        exit 0
    fi
    load_configuration $PROFILE_FILENAME
}

# Functions
handle_arguments() {
    while getopts ":p:htd" opt;do
        case $opt in
            h)
                help_message
                display_bar
                exit 1
                ;;
            d)
                INSTALL_DEPENDENCIES="False"
                ;;
            t)
                CREATE_TMUX_SESSION="False"
                ;;
            p)
                PROFILE_FILENAME="$OPTARG"
                ;;
            \?)
                display_error "Invalid option: -$OPTARG. Exiting." >&2
                exit 1
                ;;
            :)
                display_error "Option -$OPTARG requires an argument. Exiting." >&2
                exit 1
                ;;
        esac
    done
}
install_brew() {
    which brew >/dev/null
    is_installed=$?
    if [[ is_installed -eq 0 ]];then
        display_success "Package 'brew' is already installed. Skipping."
    else
        display_info "Installing package manager 'brew' on the system."
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && display_success \
            "Package Manager brew has been successfully installed."
    fi
}
install_oh_my_zsh() {
    # TODO: update this function
    if [[ -e "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        display_warning "Skipping Installation Oh-My-ZSH (Already Installed)"
    else
        display_success "Installing: ${CWHITE}Oh-My-ZSH"
        # sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
        ${CWD}/oh-my-zsh/tools/install.sh
        display_message "Changing default shell to ZSH"
        chsh -s /usr/bin/zsh
    fi
}
install_spaceship_theme() {
    # TODO: update this function
    if [[ -e "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
        display_warning "Skipping Installation: Spaceship (Already Installed)"
    else
        display_success "[+] Installing ZSH Theme:${CWHITE} Spaceship Prompt"
        copy_recursive "${CWD}/spaceship-prompt" "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt"
        ln -s "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "${HOME}/.oh-my-zsh/themes/spaceship.zsh-theme"
    fi
}
install_docker() {
    # TODO: add macOS support
    # TODO: add Ubuntu/Debian support
    if [[ $OPERATING_SYSTEM == 'CentOS' ]];then
        case $OPERATING_SYSTEM_VERSION in
            8)
                display_info "Installing Docker"
                sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
                sudo dnf install docker-ce --nobest -y && display_success "Successfully installed docker service."
                sudo systemctl start docker && display_success "Successfully started docker service."
                sudo systemctl enable docker && display_success "Successfully enabled docker service on startup."
                sudo groupadd docker && display_success "Successfully added group 'docker'."
                sudo usermod -aG docker $USER && display_success "Successfully added $USER to group 'docker'."
                ;;
            7)
                sudo yum remove docker \
                    docker-client \
                    docker-client-latest \
                    docker-common \
                    docker-latest \
                    docker-latest-logrotate \
                    docker-logrotate \
                    docker-engine
                sudo yum install -y yum-utils \
                    device-mapper-persistent-data \
                    lvm2
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install docker-ce docker-ce-cli containerd.io  && display_success "Successfully installed docker service."
                sudo systemctl start docker && display_success "Successfully started docker service."
                sudo systemctl enable docker && display_success "Successfully enabled docker service on startup."
                sudo groupadd docker && display_success "Successfully added group 'docker'."
                sudo usermod -aG docker $USER && display_success "Successfully added $USER to group 'docker'."
                ;;
            *)
                display_warning "Unsupported Operating System version. Skipping."
                ;;
        esac
    fi
}
error_handler() {
    display_error "Program exiting due to an error. Exiting"
    exit 1
}
exit_handler() {
    display_info "Program exiting. Good bye."
}
# Main Execution
main "$@"