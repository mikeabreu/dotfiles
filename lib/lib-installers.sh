#!/usr/bin/env bash
# Author: Michael Abreu
#============================
#   Dependency Check
#============================
[[ $_LOADED_LIB_INSTALLERS == true ]] && {
    [[ $DEBUG == true ]] && display_debug "Skipping: Duplicate source attempt on lib-installers.sh."
    return 0
}
[[ -r "lib/lib-core.sh" ]] && { source "lib/lib-core.sh" || { 
        echo "LIB-INSTALLERS: Failed to load lib-core.sh, run with debug true for details"; exit 1; }
} || {  echo "LIB-INSTALLERS: Missing lib-core.sh, run with debug true for details"; exit 1; }
# [[ -r "lib/lib-dotfiles.sh" ]] && { source "lib/lib-dotfiles.sh" || { 
#         echo "LIB-INSTALLERS: Failed to load lib-dotfiles.sh, run with debug true for details"; exit 1; }
# } || {  echo "LIB-INSTALLERS: Missing lib-dotfiles.sh, run with debug true for details"; exit 1; }
#============================
#   Global Variables    
#============================

#============================
#   Private Global Variables
#============================
_LOADED_LIB_INSTALLERS=true
#============================
#   macOS Brew Installers
#============================
function install_brew {
    command_exists brew && {
        display_warning "Skipping: System Package: brew (Already Installed)"
        return 0
    }
    display_info "Installing package manager 'brew' on the system."
    # /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" &&
        display_success "Package Manager brew has been successfully installed."
    return $?
}
function install_brew_bash {
    check_bash_version && display_success "Skipping: System Package bash (Already Installed and 4.4+)" && return 0
    display_info "Installing package 'bash' with brew."
    brew install bash
    return $?
}
function install_brew_coreutils {
    command_exists timeout && {
        display_success "Skipping: System Package: coreutils (Already Installed)"
        return 0
    }
    [[ $OPERATING_SYSTEM != "Darwin" ]] && {
        display_error "Skipping: Unable to install package 'timeout'."
        return 1
    }
    # 'coreutils' is required for the use of 'timeout' in check_privileges. Mac OS Only
    display_info "Installing package 'coreutils' with brew."
    brew install coreutils && check_privileges
    return $?
}
#============================
#   Dotfile Installers       
#============================
function install_shell {
    local _shell="$1"
    [[ $OPERATING_SYSTEM == "Darwin" ]] && {
        local user_shell="$( dscl . -read /Users/testuser UserShell | awk -F':' '{print $2}' \
            | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -o "$(which $_shell)" )"
    } || {
        local user_shell="$( grep "$(whoami)" /etc/passwd | grep -o "$(which $_shell)" )"
    }
    display_bar
    display_title "Installing and changing user shell."
    [[ $DEBUG == true ]] && display_debug "User shell: '$user_shell' and desired_shell: '$_shell'"
    [[ -z "$user_shell" ]] && {
        ! command_exists "$_shell" && { install_system_package "$_shell"; }
        local new_shell="$(which $_shell)"
        [[ "$user_shell" == "$new_shell" ]] && {
            display_warning "Skipping: User shell is: $user_shell and desired shell is: $new_shell"
        } || {
            display_info "Changing user shell to: $new_shell"
            chsh -s "$new_shell"
        }
    } || { display_warning "Skipping: User shell is already set to desired shell: $user_shell"; }

}
function install_shell_framework {
    local shell_framework="$1"
    local dotfiles_home="$2"
    display_bar
    display_title "Installing Shell Framework"
    case "$shell_framework" in
        # ADD CUSTOM INSTALLERS HERE
        oh-my-zsh) install_oh_my_zsh "$dotfiles_home" ;;
        # Catch All
        *)  display_error "LIB-INSTALLERS: No installer found for shell framework. Exiting.";;
    esac
}
function install_shell_theme {
    local shell_theme="$1"
    local dotfiles_home="$2"
    display_bar
    display_title "Installing Shell Theme"
    case "$shell_theme" in
        # ADD CUSTOM INSTALLERS HERE
        spaceship-prompt) install_spaceship_theme "${dotfiles_home}/.oh-my-zsh" ;;
        # Catch All
        *)  display_error "LIB-INSTALLERS: No installer found for shell theme: $shell_theme";;
    esac
}
function install_shell_plugins {
    local plugins=($(echo "$1"))
    local dotfiles_home="$2"
    local ohmyzsh_plugins_dir="${dotfiles_home}/.oh-my-zsh/plugins"
    display_bar
    display_title "Installing Shell Plugins"
    for plugin in "${plugins[@]}"; do
        case "$plugin" in
            # ADD CUSTOM INSTALLERS HERE
            zsh-syntax-highlighting)
                [[ -e "${ohmyzsh_plugins_dir}/zsh-syntax-highlighting" ]] && {
                    display_warning "Skipping: Shell Plugin: $plugin (Already Installed)"
                } || {
                    display_info "Installing shell plugin: zsh-syntax-highlighting"
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ohmyzsh_plugins_dir}/zsh-syntax-highlighting"
                } ;;
            zsh-autosuggestions)
                [[ -e "${ohmyzsh_plugins_dir}/zsh-autosuggestions" ]] && {
                    display_warning "Skipping: Shell Plugin: $plugin (Already Installed)"
                } || {
                    display_info "Installing shell plugin: zsh-autosuggestions"
                    git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ohmyzsh_plugins_dir}/zsh-autosuggestions"
                } ;;
            # Catch All
            *)  display_warning "LIB-INSTALLERS: No installer found for shell plugin: $plugin";;
        esac
    done
}
function install_system_packages {
    local packages=($(echo "$1"))
    display_bar
    display_title "Installing System Packages"
    for package in "${packages[@]}"; do
        install_system_package $package
    done
}
#============================
#   Generic Installers       
#============================
function install_oh_my_zsh {
    local dotfiles_home="$1"
    local ohmyzsh_basedir="${dotfiles_home}/.oh-my-zsh"
    [[ -e "${ohmyzsh_basedir}/oh-my-zsh.sh" ]] && {
        display_warning "Skipping: Shell Framework: Oh-My-ZSH (Already Installed)"
        return 0
    }
    # Prevent the cloned repository from having insecure permissions. Failing to do
    # so causes compinit() calls to fail with "command not found: compdef" errors
    # for users with insecure umasks (e.g., "002", allowing group writability). Note
    # that this will be ignored under Cygwin by default, as Windows ACLs take
    # precedence over umasks except for filesystems mounted with option "noacl".
    local last_umask="$(umask)"
    umask g-w,o-w
    display_info "Cloning Oh My Zsh into 'dotfiles/_home/.oh-my-zsh'"
    git clone -c core.eol=lf -c core.autocrlf=false \
        -c fsck.zeroPaddedFilemode=ignore \
        -c fetch.fsck.zeroPaddedFilemode=ignore \
        -c receive.fsck.zeroPaddedFilemode=ignore \
        --depth=1 --branch "master" "https://github.com/ohmyzsh/ohmyzsh" "${ohmyzsh_basedir}" || {
            error "git clone of oh-my-zsh repo failed"
            exit 1
        }
    # Restoring umask
    umask "$last_umask"
}
function install_spaceship_theme {
    local ohmyzsh_dir="$1"
    [[ -d "$ohmyzsh_dir" ]] && {
        local custom_theme_dir="${ohmyzsh_dir}/custom/themes"
        [[ ! -e "${custom_theme_dir}/spaceship-prompt" ]] && {
            display_info "Installing Spaceship Prompt theme"
            git clone https://github.com/denysdovhan/spaceship-prompt.git "${custom_theme_dir}/spaceship-prompt"
            ln -s "${custom_theme_dir}/spaceship-prompt/spaceship.zsh-theme" "${custom_theme_dir}/spaceship.zsh-theme"
        } || { display_warning "Skipping: Shell Theme: Spaceship (Already Installed)"; }
    }
}
#============================
#   Custom Installers       
#============================
function install_docker {
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
                display_warning "Skipping: Unsupported Operating System version."
                ;;
        esac
    fi
}
#============================
#   Main Execution / Initialization
#============================
[[ $DEBUG == true ]] && display_debug "Loaded lib-installers.sh file"
return 0