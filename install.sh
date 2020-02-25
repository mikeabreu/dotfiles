#!/usr/bin/env bash
#
# Dotfiles
# Mike Abreu
#
# Goals:
# 1. From fresh boot to configured terminal environment
# 2. Support for major operating systems (Latest) excluding Windows
#     - macOS, CentOS, Debian, Ubuntu
# 3. Allow different configurations from one dotfiles

# Todo:
# - Uninstall changes
#     -> Uninstall all features or only some features

# - Feature: Install Shell
#     |>All Profiles
#     -> Install zsh
#         => macOS: default option || brew install zsh
#         => Ubuntu/Debian: apt install zsh
#         => CentOS/RedHat: dnf install zsh || yum install zsh || rpm install zsh
#         => OpenBSD:
#     -> Change shell for user to zsh
#         => all: chsh -s /bin/zsh
#     -> Update oh-my-zsh submodule
#         => all: git submodule update --init
#     -> Install oh-my-zsh
#         -> Remove lines from install.sh script that stop automation. (i.e. env and chsh)
#             => all: 
#         => all: 
#     -> Install spaceship prompt
#         => all:
#     -> Install zsh-autocomplete
#         => all:
#     -> Install: zsh-syntaxhighlight
#         => all:
#     -> Create symlink for ~/.zshrc to ~/dotfiles/.zshrc
# - Feature: Install Text Editor
#     |>Headless Profile
#     -> Install vim
#     -> Create symlink for ~/.vimrc to ~/dotfiles/.vimrc
#     |>GUI Profile
#     -> Install Visual Studio Code
#     -> Create symlink for <<Config File Locations>>
#     -> Install Extensions
# - Feature: Install Fonts
#     |>GUI Profile
#     -> Install Fira Code
#         => macOS: brew tap homebrew/cask-fonts;brew install font-fira-code
# - Feature: Install tmux
#     |> All Profiles
#     -> Install tmux
#     -> Create symlink for <<Config File Locations>>
# - Feature: Install grc
#     |> All Profiles
#     -> Install grc
#     -> Create symlink for <<Config File Locations>>
# - Feature: Install Common PowerTools
#     |> No Profiles
#     -> Install axel
#     -> Install ipsets
#     -> Install fail2ban
#     -> Install iptables
#     -> Install gpg

# Imports
source lib-core.sh
source lib-config.sh

# Global Variables
DEPENDENCIES_INSTALLED="False"
TMUX_ATTACHED="False"

# Main
main() {
    check_operating_system
    handle_arguments "$@"

    if [[ $DEPENDENCIES_INSTALLED == "False" ]];then
        # Welcome Prompt
        help_message

        # Determine operating system and version
        display_bar
        display_info "OPERATING_SYSTEM: ${OPERATING_SYSTEM}"
        display_info "OPERATING_SYSTEM_VERSION: ${OPERATING_SYSTEM_VERSION}"

        # Install dependencies for dotfiles to operate
        display_bar
        display_info "Installing dotfile dependencies"
        install_system_package "jq"
        install_system_package "stow"
        install_system_package "tmux"
    fi

    display_bar
    if [[ $TMUX_ATTACHED == "False" ]];then
        # Load tmux
        tmux list-sessions | grep "dotfiles"
        if [[ $? -eq 1 ]]; then
            display_info "Tmux: Starting new-session 'dotfiles'"
            tmux new-session -d -s dotfiles
        fi
        display_info "Tmux: Attaching to session 'dotfiles'"
        tmux send-keys "sh ./install.sh -bd" Enter
        tmux attach-session -t dotfiles
        display_warning "Tmux: Continuing execution in tmux session. Exiting."
        exit 0
    fi
    load_configuration $PROFILE_FILENAME
}

# Functions
handle_arguments() {
    PROFILE_FILENAME="None"
    while getopts ":p:hbd" opt;do
        case $opt in
            h)
                display_bar
                exit 1
                ;;
            d)
                DEPENDENCIES_INSTALLED="True"
                ;;
            b)
                TMUX_ATTACHED="True"
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

install_oh_my_zsh() {
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
    if [[ -e "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
        display_warning "Skipping Installation: Spaceship (Already Installed)"
    else
        display_success "[+] Installing ZSH Theme:${CWHITE} Spaceship Prompt"
        copy_recursive "${CWD}/spaceship-prompt" "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt"
        ln -s "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "${HOME}/.oh-my-zsh/themes/spaceship.zsh-theme"
    fi
}

# install_docker() {
    # if OS = CentOS and OS_V = CentOS 8
    # Install Docker
    # dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    # dnf install docker-ce --nobest -y
    # systemctl start docker
    # systemctl enable docker

    # if OS = CentOS and OS_V = CentOS 7
    # Install Docker
    # sudo yum remove docker \
    #              docker-client \
    #              docker-client-latest \
    #              docker-common \
    #              docker-latest \
    #              docker-latest-logrotate \
    #              docker-logrotate \
    #              docker-engine
    # sudo yum install -y yum-utils \
    #     device-mapper-persistent-data \
    #     lvm2
    # sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    # sudo yum install docker-ce docker-ce-cli containerd.io
    # sudo systemctl start docker
    # sudo systemctl enable docker
    # sudo groupadd docker
    # sudo usermod -aG docker $USER
# }
help_message() {
    display_bar
    display_message """
    dotfiles - Mike Abreu
    This script will configure your terminal environment.

    Options:
    -p          Load a profile from json file.

    Examples:
    ./install.sh
    ./install.sh -p profile-gui.json
    """
}
# Main Execution
main "$@"