#!/usr/bin/env bash
# Author: Michael Abreu
# Version: 0.1.0
#============================
#   Dependency Check
#============================
REQUIRE_BASH_4_4=true
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
check_bash_version
#============================
#   Global Variables    
#============================
DOTFILES="${HOME}/dotfiles"
DOTFILES_HOME="${DOTFILES}/_home"
DOTFILES_ETC="${DOTFILES}/_etc"
DOTFILES_BIN="${DOTFILES}/_bin"
DOTFILES_LOGS="${DOTFILES}/_logs" && LIBCORE_LOGS="$DOTFILES_LOGS"
DOTFILES_CONFIGS="${DOTFILES}/configs"
DOTFILES_CONFIGS_HOME="${DOTFILES_CONFIGS}/home"
DOTFILES_CONFIGS_ETC="${DOTFILES_CONFIGS}/etc"
DOTFILES_TOOLS="${DOTFILES}/tools"
#============================
#   Private Global Variables
#============================
_LOADED_LIB_DOTFILES=true
#============================
#   Configuration Structure
#============================
[[ -z "$DOTFILES_PROFILE" ]] && declare -A DOTFILES_PROFILE=(
    [NAME]="default"
    [SHELL]="zsh"
    [SHELL_FRAMEWORK]="oh-my-zsh"
    [SHELL_THEME]="spaceship-prompt"
    [SHELL_PLUGINS]=$(_arr=(
        "git" 
        "tmux"
        "zsh-syntax-highlighting" 
        "zsh-autosuggestions"
    ) && echo "${_arr[@]}")
    [SHELL_PLUGINS_INSTALL]=$(_arr=(
        "zsh-syntax-highlighting "
        "zsh-autosuggestions"
    ) && echo "${_arr[@]}")
    [SHELL_PLUGINS_NOINSTALL]=$(_arr=(
        "git"
        "tmux"
    ) && echo "${_arr[@]}")
    [SYSTEM_PACKAGES]=$(_arr=(
        "git"
        "tmux"
        "vim"
    ) && echo "${_arr[@]}")
    [CONFIGS_HOME]=$(_arr=(
        "${DOTFILES_CONFIGS_HOME}/zsh/.zshrc_default"
        "${DOTFILES_CONFIGS_HOME}/iterm2/main.json"
        "${DOTFILES_CONFIGS_HOME}/ssh/ssh_config"
        "${DOTFILES_CONFIGS_HOME}/vim/.vimrc_default"
        "${DOTFILES_CONFIGS_HOME}/vscode/settings.json"
    ) && echo "${_arr[@]}")
    [CONFIGS_ETC]=$(_arr=(
        "${DOTFILES_CONFIGS_ETC}/ssh/sshd_config"
    ) && echo "${_arr[@]}")
    [CONFIGS_ETC_SYMLINK]=true
    [TOOLS]=$(_arr=(
        "${DOTFILES_TOOLS}/tmp.sh"
    ) && echo "${_arr[@]}")
)
#============================
#   Functions
#============================
function load_profile() {
    # Function Details:
    #   Syntax: load_profile filename_of_profile
    #
    PROFILE_FILENAME=${PROFILE_FILENAME:-1}
    # Check if jq is installed
    ! command_exists jq && display_error "Command 'jq' is missing from PATH. Exiting." && exit 1
    # Load profile
    if [[ $1 == "None" ]];then
        PROFILE_SELECTED='default'
        PROFILE_FILENAME='profiles/default.json'
    else
        PROFILE_SELECTED=$(jq '.name' $1)
    fi
    # Check that the structure of profile is valid
    validate_profile
    # Show the user the profile being loaded
    display_profile
}
function install_profile() {
    # Function Details:
    #   Syntax: install_profile filename_of_profile
    #
    # Prompt user to continue with installation
    prompt_user message="Do you wish to install this profile [Y/n]:" \
        success_message="Continuing with profile installation." \
        failure_message="User chose to not load profile. Exiting." \
          error_message="Invalid option. Exiting."
    # If still executing, user wanted to install profile.
    #TODO: install shell
    install_shell
    #TODO: install shell framework
    install_shell_framework
    #TODO: install shell theme
    # _install_shell_theme
    #TODO: install all shell plugins
    install_shell_plugins
    #TODO: install all packages.
    install_system_packages
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
function validate_profile {
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
#   Dotfile Config Installers       
#============================
function install_shell {
    display_bar
    display_header "Installing/Configuring Shell"
    which $_CONFIG_SHELL >/dev/null
    local is_installed=$?
    if [[ $is_installed -ne 0 ]];then
        install_system_package $_CONFIG_SHELL
    fi
    local new_shell=$(which $_CONFIG_SHELL)    
    display_info "Changing user shell to '${new_shell}'"
    chsh -s $new_shell
}
function install_shell_framework {
    display_bar
    display_header "Installing Shell Framework"
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
function install_shell_theme {
    display_bar
    display_header "Installing Shell Theme"
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
function install_shell_plugins {
    display_bar
    display_header "Installing Shell Plugins"
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
function install_system_packages {
    display_bar
    display_header "Installing Packages"
    for package in ${_CONFIG_PACKAGES[@]}; do
        install_system_package $package
        if [[ $_LAST_ELEVATED_CMD_EXIT_CODE -ne 0 ]]; then
            display_error "Package '${package}' had an error occur while installing."
        fi
    done
}