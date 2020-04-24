#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
#============================
#   Dependency Check
#============================
if [[ $_LOADED_LIB_CORE == false ]];then
    if [[ -e lib-core.sh ]];then
        source lib-core.sh
    elif [[ -e "${HOME}/dotfiles/lib/lib-core.sh" ]];then
        source "${HOME}/dotfiles/lib/lib-core.sh"
    else
        echo "Missing lib-core.sh. Exiting."
        exit 1
    fi
fi

#============================
#   Configuration Structure
#============================
# _CONFIG_NAME | String of profile name
#       -> Default: "default"
# _CONFIG_SAFE_FILE | String of True/False for using Safe File Replacement
#       -> Default: "True"
# _CONFIG_SHELL | String of shell
#       -> Default: "zsh"
# _CONFIG_SHELL_FRAMEWORK | String of shell framework
#       -> Default: "oh-my-zsh"
# _CONFIG_SHELL_THEME | String of oh-my-zsh theme
#       -> Default: "spaceship-prompt"
# _CONFIG_SHELL_PLUGINS | Array of plugins to add to zshrc
#       -> Default: ( "git" "tmux" )
# _CONFIG_SHELL_PLUGINS_NONINSTALL | Array of plugins that dont require installation
#       -> Default: ( "git" "tmux" )
# _CONFIG_SHELL_PLUGINS_INSTALL | Array of plugins to install
#       -> Default: ( "zsh-autosuggestions" "zsh-syntax-highlighting" )
# _CONFIG_PACKAGES | Array of packages to install
#       -> Default: ( "vim" "git" "curl" "wget" "grc" "htop" )

#============================
#   Global Variables    
#============================
_G_PACKAGE_ERROR_LIST=()

#============================
#   Functions
#============================
function load_profile() {
    # Function Details:
    #   Syntax: load_profile filename_of_profile
    #
    PROFILE_FILENAME=${PROFILE_FILENAME:-1}
    # Check if jq is installed
    which jq >/dev/null
    is_installed=$?
    if [[ is_installed -ne 0 ]];then
        display_error "Command 'jq' is missing from PATH. Exiting."
        exit 1
    fi
    # Load profile
    if [[ $1 == "None" ]];then
        PROFILE_SELECTED='default'
        PROFILE_FILENAME='profiles/default.json'
    else
        PROFILE_SELECTED=$(jq '.name' $1)
    fi
    # Check that the structure of profile is valid
    _config_validate
    # Show the user the profile being loaded
    display_profile
}
function install_profile() {
    # Function Details:
    #   Syntax: install_profile filename_of_profile
    #
    # Prompt user to continue with installation
    display_prompt "Do you wish to install this profile [Y/n]:"
    read user_response
    # Default to Yes
    user_response=${user_response:-"Y"}
    case $user_response in
        [yY][eE][sS]|[yY])
            display_info "Continuing with profile installation."
            ;;
        [nN][oO]|[nN])
            display_warning "User chose to not load profile. Exiting."
            exit 1
            ;;
        *)
            display_error "Invalid option. Exiting."
            exit 1
            ;;
    esac
    # If still executing, user wanted to install profile.
    #TODO: install shell
    _install_shell
    #TODO: install shell framework
    _install_shell_framework
    #TODO: install shell theme
    # _install_shell_theme
    #TODO: install all shell plugins
    _install_shell_plugins
    #TODO: install all packages.
    _install_packages
    display_bar
}
function display_profile() {
    display_message "${CGREEN}PROFILE_NAME:${CE} ${CWHITE} ${_CONFIG_NAME}"
    display_bar
    display_message "${CGREEN}SHELL:${CE} ${CWHITE} ${_CONFIG_SHELL}"
    display_message "${CGREEN}SHELL_FRAMEWORK:${CE} ${CWHITE} ${_CONFIG_SHELL_FRAMEWORK}"
    display_message "${CGREEN}SHELL_THEME:${CE} ${CWHITE} ${_CONFIG_SHELL_THEME}"
    display_message "${CGREEN}SHELL_PLUGINS:${CE}"
    for plugin in ${_CONFIG_SHELL_PLUGINS_NONINSTALL[@]}; do
        display_message "\t${CGREEN}- PLUGIN:${CE} ${CWHITE} ${plugin}"
    done
    display_message "${CGREEN}SHELL_PLUGINS_INSTALL:${CE}"
    for plugin in ${_CONFIG_SHELL_PLUGINS_INSTALL[@]}; do
        display_message "\t${CGREEN}- PLUGIN:${CE} ${CWHITE} ${plugin}"
    done
    display_message "${CGREEN}PACKAGES:${CE}"
    for package in ${_CONFIG_PACKAGES[@]}; do
        display_message "\t${CGREEN}- PACKAGE:${CE} ${CWHITE} ${package}"
    done
    display_bar
}
#============================
#   Helper Functions
#============================
function _config_validate {
    display_info "Validating profile."
    #
    # Validate: Name
    # display_message "Validate: Name"
    _CONFIG_NAME_LENGTH=$(jq '.name | length' $PROFILE_FILENAME 2>/dev/null)
    if [[ $_CONFIG_NAME_LENGTH -eq 0 ]];then
        # Error: No Name Provided, Defaulting to 'default'
        display_warning "Config Schema: 'name' not found, defaulting to \"default\"."
        _CONFIG_NAME="default"
    else
        _CONFIG_NAME=$(jq '.name' $PROFILE_FILENAME | sed 's/"//g')
    fi
    #
    # Validate: Shell
    # display_message "Validate: Shell"
    _CONFIG_SHELL_LENGTH=$(jq '.shell | length' $PROFILE_FILENAME 2>/dev/null)
    if [[ $_CONFIG_SHELL_LENGTH -eq 0 ]];then
        # Error: No Shell Provided, Defaulting to 'zsh'
        display_warning "Config Schema: 'shell' not found, defaulting to \"zsh\"."
        _CONFIG_SHELL="zsh"
    else
        _CONFIG_SHELL=$(jq '.shell' $PROFILE_FILENAME | sed 's/"//g')
    fi
    #
    # Validate: Shell Framework
    # display_message "Validate: Shell Framework"
    _CONFIG_SHELL_FRAMEWORK_LENGTH=$(jq '.shell_framework | length' $PROFILE_FILENAME 2>/dev/null)
    if [[ $_CONFIG_SHELL_FRAMEWORK_LENGTH -eq 0 ]];then
        # Error: No Shell Framework Provided, Defaulting to 'oh-my-zsh'
        display_warning "Config Schema: 'shell_framework' not found, defaulting to \"oh-my-zsh\"."
        _CONFIG_SHELL_FRAMEWORK="oh-my-zsh"
    else
        _CONFIG_SHELL_FRAMEWORK=$(jq '.shell_framework' $PROFILE_FILENAME | sed 's/"//g')
    fi
    #
    # Validate: Shell Theme
    # display_message "Validate: Shell Theme"
    _CONFIG_SHELL_THEME_LENGTH=$(jq '.shell_theme | length' $PROFILE_FILENAME 2>/dev/null)
    if [[ $_CONFIG_SHELL_THEME_LENGTH -eq 0 ]];then
        # Error: No Shell Framework Provided, Defaulting to 'oh-my-zsh'
        display_warning "Config Schema: 'shell_theme' not found, defaulting to \"spaceship-prompt\"."
        _CONFIG_SHELL_THEME="spaceship-prompt"
    else
        _CONFIG_SHELL_THEME=$(jq '.shell_theme' $PROFILE_FILENAME | sed 's/"//g')
    fi
    #
    # Validate: Shell Plugins
    # display_message "Validate: Shell Plugins"
    _CONFIG_SHELL_PLUGINS_LENGTH=$(jq '.shell_plugins | length' $PROFILE_FILENAME 2>/dev/null)
    if [[ $_CONFIG_SHELL_PLUGINS_LENGTH -eq 0 ]];then
        # Error: No Shell Framework Provided, Defaulting to 'oh-my-zsh'
        display_warning "Config Schema: 'shell_plugins' not found, defaulting to ( \"git\" )."
        _CONFIG_SHELL_PLUGINS_NONINSTALL=(
            "git"
            "tmux"
        )
        _CONFIG_SHELL_PLUGINS=(
            "git"
            "tmux"
        )
    else
        _CONFIG_SHELL_PLUGINS_NONINSTALL=$(jq '.shell_plugins[] | select(.install != true) | .name' $PROFILE_FILENAME | sed s/\"//g)
        _CONFIG_SHELL_PLUGINS=$(jq '.shell_plugins[] | .name' $PROFILE_FILENAME | sed s/\"//g)
    fi
    #
    # Validate: Shell Plugins Install List
    # display_message "Validate: Shell Plugin Install List"
    _CONFIG_SHELL_PLUGINS_INSTALL_LENGTH=$(jq '.shell_plugins[] | select(.install == true) | length' $PROFILE_FILENAME 2>/dev/null | head -n1)
    if [[ $_CONFIG_SHELL_PLUGINS_INSTALL_LENGTH -eq 0 ]]; then
        display_warning "Config Schema: 'shell_plugins' with 'install' not found, defaulting to ( \"zsh-autosuggestions\" \"zsh-syntax-highlighting\" )."
        _CONFIG_SHELL_PLUGINS_INSTALL=(
            "zsh-autosuggestions"
            "zsh-syntax-highlighting"
        )
        _CONFIG_SHELL_PLUGINS+=(
            "zsh-autosuggestions"
            "zsh-syntax-highlighting"
        )
    else
        _CONFIG_SHELL_PLUGINS_INSTALL=$(jq '.shell_plugins[] | select(.install == true) | .name' $PROFILE_FILENAME | sed 's/"//g')
    fi
    #
    # Validate: Packages
    # display_message "Validate: Packages"
    _CONFIG_PACKAGES_LENGTH=$(jq '.packages | length' $PROFILE_FILENAME 2>/dev/null)
    if [[ $_CONFIG_PACKAGES_LENGTH -eq 0 ]];then
        # Error: No Shell Framework Provided, Defaulting to 'oh-my-zsh'
        display_warning "Config Schema: 'packages' not found, defaulting to ( \"vim\" \"git\" \"curl\" \"wget\" \"grc\" \"htop\" )"
        # TODO: Decide default packages.
        _CONFIG_PACKAGES=(
            "vim"
            "git"
            "curl"
            "wget"
            "grc"
            "htop"
        )
    else
        _CONFIG_PACKAGES=$(jq '.packages[] | .name' $PROFILE_FILENAME | sed s/\"//g)
    fi
    display_bar
}
#============================
#   Core Installers       
#============================
function _install_shell {
    display_bar
    display_message "Installing/Configuring Shell"
    which $_CONFIG_SHELL >/dev/null
    local is_installed=$?
    if [[ $is_installed -ne 0 ]];then
        install_system_package $_CONFIG_SHELL
    fi
    local new_shell=$(which $_CONFIG_SHELL)    
    display_info "Changing user shell to '${new_shell}'"
    chsh -s $new_shell
}
function _install_shell_framework {
    display_bar
    display_message "Installing Shell Framework"
    case $_CONFIG_SHELL_FRAMEWORK in
        oh-my-zsh)
            _install_oh_my_zsh
            ;;
        *)
            display_error "Unsupported shell framework. Exiting."
            exit 1
            ;;
    esac
}
function _install_shell_theme {
    display_bar
    display_message "Installing Shell Theme"
    case $_CONFIG_SHELL_THEME in
        spaceship-prompt)
            display_info "Installing Spaceship Prompt theme"
            _install_spaceship_theme
            ;;
        *)
            display_warning "Adding theme to zshrc. Skipping any installation."
            ;;
    esac
}
function _install_shell_plugins {
    display_bar
    display_message "Installing Shell Plugins"
    for plugin in ${_CONFIG_SHELL_PLUGINS[@]}; do
        case $plugin in
            zsh-syntax-highlighting)
                if [[ -e "${DOTFILES_HOME}/.oh-my-zsh/plugins/zsh-syntax-highlighting" ]];then
                    display_success "Skipping. $plugin is already installed."
                else
                    display_info "Installing shell plugin: zsh-syntax-highlighting" \
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${DOTFILES_HOME}/.oh-my-zsh/plugins/zsh-syntax-highlighting"
                fi
                ;;
            zsh-autosuggestions)
                if [[ -e "${DOTFILES_HOME}/.oh-my-zsh/plugins/zsh-autosuggestions" ]];then
                    display_success "Skipping. $plugin is already installed."
                else
                    display_info "Installing shell plugin: zsh-autosuggestions"
                    git clone https://github.com/zsh-users/zsh-autosuggestions.git "${DOTFILES_HOME}/.oh-my-zsh/plugins/zsh-autosuggestions"
                fi
                ;;
            *)
                display_warning "Unsupported plugin: '${plugin}'. Skipping installation steps."
                ;;
        esac
    done
    sed "s|%%PLUGIN_LIST%%|$(echo ${_CONFIG_SHELL_PLUGINS[@]})|g" "configs/zsh/.zshrc_default" > "${DOTFILES_HOME}/.zshrc"
}
function _install_packages {
    display_bar
    display_message "Installing Packages"
    for package in ${_CONFIG_PACKAGES[@]}; do
        install_system_package $package
        if [[ $_LAST_ELEVATED_CMD_EXIT_CODE -ne 0 ]]; then
            display_error "Package '${package}' had an error occur while installing."
        fi
    done
}
#============================
#   Custom Installers       
#============================
function _install_oh_my_zsh {
    if [[ -e "${DOTFILES_HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        display_warning "Skipping Installation Oh-My-ZSH (Already Installed)"
        return
    fi
    # Prevent the cloned repository from having insecure permissions. Failing to do
    # so causes compinit() calls to fail with "command not found: compdef" errors
    # for users with insecure umasks (e.g., "002", allowing group writability). Note
    # that this will be ignored under Cygwin by default, as Windows ACLs take
    # precedence over umasks except for filesystems mounted with option "noacl".
    umask g-w,o-w

    display_info "${CBLUE}Cloning Oh My Zsh...${CE}"

    command_exists git || {
        error "git is not installed"
        exit 1
    }

    if [ "$OPERATING_SYSTEM" = cygwin ] && git --version | grep -q msysgit; then
        error "Windows/MSYS Git is not supported on Cygwin"
        error "Make sure the Cygwin git package is installed and is first on the \$PATH"
        exit 1
    fi

    git clone -c core.eol=lf -c core.autocrlf=false \
        -c fsck.zeroPaddedFilemode=ignore \
        -c fetch.fsck.zeroPaddedFilemode=ignore \
        -c receive.fsck.zeroPaddedFilemode=ignore \
        --depth=1 --branch "master" "https://github.com/ohmyzsh/ohmyzsh" "${DOTFILES_HOME}/.oh-my-zsh" || {
        error "git clone of oh-my-zsh repo failed"
        exit 1
    }
}
function _install_spaceship_theme {
    # TODO: update this function
    if [[ -e "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
        display_warning "Skipping Installation: Spaceship (Already Installed)"
    else
        display_success "[+] Installing ZSH Theme:${CWHITE} Spaceship Prompt"
        copy_recursive "${CWD}/spaceship-prompt" "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt"
        ln -s "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "${HOME}/.oh-my-zsh/themes/spaceship.zsh-theme"
    fi
}
function _install_docker {
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