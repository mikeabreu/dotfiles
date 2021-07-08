#!/usr/bin/env bash
# Author: Michael Abreu
#========================================================
#   Dependency Check
#========================================================
# Prevent duplicate sourcing
[[ $_LOADED_LIB_INSTALLERS == true ]] && {
    [[ $DEBUG == true ]] && display_debug "Skipping: Duplicate source attempt on lib-installers.sh."
    return 0
}
#========================================================
#   Global Variables    
#========================================================
declare _LOADED_LIB_INSTALLERS=true
declare _SYSTEM_PACKAGE_MANAGER_UPDATED=false
#========================================================
#   System Package Management 
#========================================================
function update_system_package {
    case "$OPERATING_SYSTEM" in
        Ubuntu | Debian) run_elevated_cmd apt-get update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true ;;
        CentOS) run_elevated_cmd yum update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true ;;
        Darwin) run_elevated_cmd brew update && _SYSTEM_PACKAGE_MANAGER_UPDATED=true ;;
        *)  display_error "Unknown system package manager. Exiting."; exit 1 ;;
    esac
}
function install_system_package {
    local package_name="$1"
    command_exists $package_name && {
        display_warning "Skipping: System Package is already installed:" "$package_name"
        return 0
    }
    display_title "Attempting to install system package:" "$package_name"
    # If system package manager hasn't been updated, then update it
    [[ $_SYSTEM_PACKAGE_MANAGER_UPDATED == false ]] && {
        display_info "Updating system packages"
        update_system_package
        display_bar
    }
    # Determine which system package manager to use by OS
    case "$OPERATING_SYSTEM" in
        Ubuntu|Debian)  
            # Use 'apt'
            run_elevated_cmd apt-get install -y $package_name && {
                display_success "Successfully installed system package" "$package_name"
                return 0
            } || {
                display_error "Skipping: Something went wrong during system package installation."
                return 1
            } ;;
        CentOS) 
            # Use 'yum'
            run_elevated_cmd yum install -y $package_name && {
                display_success "Successfully installed system package" "$package_name"
                return 0
            } || {
                display_error "Skipping: Something went wrong during system package installation."
                return 1
            } ;;
        Darwin) 
            # Use 'brew'
            run_elevated_cmd brew install $package_name && {
                display_success "Successfully installed system package" "$package_name"
                return 0
            } || {
                display_error "Skipping: Something went wrong during system package installation."
                return 1
            } ;;
        *)  display_error "Unknown system package manager. Exiting."; exit 1 ;;
    esac
    # If it didnt return from the case switch, return unsuccessfully.
    return 1
}
#========================================================
#   macOS Brew Installers
#========================================================
function install_brew {
    command_exists brew && {
        display_warning "Skipping: System Package is already installed:" "brew"
        display_bar
        return 0
    }
    display_title "Installing homebrew the package manager"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" &&
        display_success "Homebrew has been successfully installed."
    display_bar
    return $?
}
function install_brew_bash {
    check_bash_version && {
        display_warning "Skipping: System Package is already installed:" "bash (4.4+)"
        display_bar
        return 0
    }
    display_info "Installing package bash with brew."
    brew install bash &&
        display_success "Package: ${CWHITE}bash${CLGREEN} has been successfully installed."
    display_bar
    return $?
}
function install_brew_coreutils {
    command_exists timeout && {
        display_warning "Skipping: System Package is already installed:" "coreutils"
        display_bar
        return 0
    }
    # 'coreutils' is required for the use of 'timeout' in check_privileges. 
    # Need to install for Mac OS, installed by default on Ubuntu, Debian, CentOS
    display_info "Installing package coreutils with brew."
    brew install coreutils &&
        display_success "Package: coreutils has been successfully installed."
    display_bar
    return $?
}
#========================================================
#   Dotfile Installers       
#========================================================
function install_shell {
    # _shell comes from profile.json 'SHELL'
    local desired_shell="$1"
    # Determine current users login
    [[ $OPERATING_SYSTEM == "Darwin" ]] && {
        # Mac OS Check
        local user_shell="$( dscl . -read /Users/$(whoami) UserShell | awk -F':' '{print $2}' \
            | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -o "$(which $desired_shell)" )"
    } || {
        # Linux Check
        local user_shell="$( grep "$(whoami)" /etc/passwd | grep -o "$(which $desired_shell)" )"
    }
    display_bar
    display_title "Installing and changing user shell."
    display_bar
    # If user_shell is empty then the login shell isn't the desired shell
    [[ -z "$user_shell" ]] && {
        # Check if the desired shell exists, install it if not.
        ! command_exists "$desired_shell" && { install_system_package "$desired_shell"; }
        # Grab desired shell path
        local new_shell="$(which $desired_shell)"
        # Change the users login shell to the desired shell
        display_info "Changing user shell to:" "$new_shell"
        chsh -s "$new_shell"
    } || { display_warning "Skipping: User shell is: ${CWHITE}${user_shell}${CYELLOW} and desired shell is: ${CWHITE}$(which $desired_shell)"; }
    display_bar
}
function install_shell_framework {
    # shell_framework comes from profile.json 'SHELL_FRAMEWORK'
    # dotfiles_home="${HOME}/dotfiles/_home"
    local shell_framework="$1"
    local dotfiles_home="$2"
    display_title "Installing Shell Framework"
    display_bar
    case "$shell_framework" in
        # ADD CUSTOM SHELL FRAMEWORK INSTALLER HERE
        oh-my-zsh) install_oh_my_zsh "$dotfiles_home" ;;
        # Catch All
        *)  display_error "LIB-INSTALLERS: No installer found for shell framework" "$shell_framework";;
    esac
}
function install_shell_theme {
    # shell_theme comes from profile.json 'SHELL_THEME'
    # dotfiles_home="${HOME}/dotfiles/_home"
    local shell_theme="$1"
    local dotfiles_home="$2"
    display_title "Installing Shell Theme"
    display_bar
    case "$shell_theme" in
        # ADD CUSTOM SHELL THEME INSTALLER HERE
        spaceship-prompt) install_spaceship_theme "${dotfiles_home}/.oh-my-zsh" ;;
        # Catch All
        *)  display_error "LIB-INSTALLERS: No installer found for shell theme:" "$shell_theme";;
    esac
}
function install_shell_plugins {
    # plugins comes from profile.json 'SHELL_PLUGINS'
    # dotfiles_home="${HOME}/dotfiles/_home"
    local plugins=($(echo "$1"))
    local dotfiles_home="$2"
    local ohmyzsh_plugins_dir="${dotfiles_home}/.oh-my-zsh/plugins"
    display_title "Installing Shell Plugins"
    display_bar
    for plugin in "${plugins[@]}"; do
        case "$plugin" in
            # ADD CUSTOM SHELL PLUGIN INSTALLER HERE
            zsh-syntax-highlighting)
                [[ -e "${ohmyzsh_plugins_dir}/zsh-syntax-highlighting" ]] && {
                    display_warning "Skipping: Shell Plugin is already installed:" "$plugin"
                } || {
                    display_info "Installing shell plugin:" "zsh-syntax-highlighting"
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ohmyzsh_plugins_dir}/zsh-syntax-highlighting"
                }
                display_bar ;;
            zsh-autosuggestions)
                [[ -e "${ohmyzsh_plugins_dir}/zsh-autosuggestions" ]] && {
                    display_warning "Skipping: Shell Plugin is already installed:" "$plugin"
                } || {
                    display_info "Installing shell plugin:" "zsh-autosuggestions"
                    git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ohmyzsh_plugins_dir}/zsh-autosuggestions"
                } 
                display_bar ;;
            # Catch All
            *)  display_warning "LIB-INSTALLERS: No installer found for shell plugin:" "$plugin";;
        esac
    done
}
function install_custom_installers {
    # installers comes from profile.json 'CUSTOM_INSTALLERS'
    # dotfiles_root_dir="${HOME}/dotfiles"
    local installers=($(echo "$1"))
    local dotfiles_root_dir="$2"
    display_title "Installing Custom Installers"
    display_bar
    for installer in "${installers[@]}"; do
        case "$installer" in
            # ADD CUSTOM INSTALLERS HERE
            iterm2)         install_iterm2 ;;
            amix/vimrc)     install_amix_vimrc ;;
            # Catch All
            *)  display_warning "LIB-INSTALLERS: No installer found for custom install:" "$installer"; display_bar ;;
        esac
    done
}
function install_system_packages {
    # packages comes from profile.json 'SYSTEM_PACKAGES'
    local packages=($(echo "$1"))
    display_title "Installing System Packages"
    display_bar
    for package in "${packages[@]}"; do
        # Call lib-core.sh:install_system_package to determine right system package manager and 
        # handle the permissions accordingly (i.e. not calling sudo with brew on macOS)
        install_system_package $package
        display_bar
    done
}
#========================================================
#   Generic Installers       
#========================================================
function install_oh_my_zsh {
    # dotfiles_home="${HOME}/dotfiles/_home"
    local dotfiles_home="$1"
    local ohmyzsh_basedir="${dotfiles_home}/.oh-my-zsh"
    [[ -e "${ohmyzsh_basedir}/oh-my-zsh.sh" ]] && {
        display_warning "Skipping: Shell Framework is already installed:" "oh-my-zsh"
        display_bar
        return 0
    }
    # Prevent the cloned repository from having insecure permissions. Failing to do
    # so causes compinit() calls to fail with "command not found: compdef" errors
    # for users with insecure umasks (e.g., "002", allowing group writability). Note
    # that this will be ignored under Cygwin by default, as Windows ACLs take
    # precedence over umasks except for filesystems mounted with option "noacl".
    local last_umask="$(umask)"
    umask g-w,o-w
    display_info "Installing Oh My Zsh"
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
    display_bar
}
function install_spaceship_theme {
    # ohmyzsh_dir="${HOME}/dotfiles/_home/.oh-my-zsh"
    local ohmyzsh_dir="$1"
    [[ -d "$ohmyzsh_dir" ]] && {
        # oh-my-zsh directory exists
        local custom_theme_dir="${ohmyzsh_dir}/custom/themes"
        [[ ! -e "${ohmyzsh_dir}/themes/spaceship.zsh-theme" ]] && {
            # theme doesnt exist in oh-my-zsh
            display_info "Installing Spaceship Prompt theme"
            [[ ! -d "${custom_theme_dir}/spaceship-prompt" ]] && { 
                # theme hasn't been installed before, install it
                git clone https://github.com/denysdovhan/spaceship-prompt.git "${custom_theme_dir}/spaceship-prompt"
            }
            # link installed theme to theme dir in oh-my-zsh
            ln -s "${custom_theme_dir}/spaceship-prompt/spaceship.zsh-theme" "${ohmyzsh_dir}/themes/spaceship.zsh-theme"
        } || { display_warning "Skipping: Shell Theme is already installed." "spaceship"; }
    }
    display_bar
}
#========================================================
#   Custom Installers       
#========================================================
function install_firacode {
    local dotfiles_home=$1
    [[ $OPERATING_SYSTEM == 'Darwin' ]] && {
        display_warning "install firacode manually at https://github.com/tonsky/FiraCode/tree/master/distr/ttf."
        return 0
    }
    display_info "Installing firacode"
    install_system_package "fonts-firacode"
}
function install_amix_vimrc {
    local dotfiles_home=$1
    display_info "Installing amix/vimrc"
    git clone --depth=1 https://github.com/amix/vimrc.git "${dotfiles_home}/.vim_runtime"
    display_bar
}
function install_iterm2 {
    [[ $OPERATING_SYSTEM != 'Darwin' ]] && {
        # If not macOS just return 1 for false.
        return 1
    }
    [[ -e "/Applications/iTerm.app" ]] && {
        display_warning "Skipping: iTerm2 is already installed in /Applications/iTerm2.app"
        return 0
    }
    display_bar
    display_title "Installing iTerm2"
    local download_link="$( curl https://iterm2.com/downloads.html 2>/dev/null  |
        grep -oE '<a\s+(?:[^>]*?\s+)?href=(["])(.*?)\1'                             | 
        grep "stable" | head -n1 | awk -F'"' '{print $2}')"
    # alternative with pup
    # local download_link="$( curl https://iterm2.com/downloads.html 2>/dev/null | pup 'a[href*="stable"] attr{href}' | head -n1)"
    local filename="$(echo "$download_link" | awk -F'/' '{print $NF}')"
    display_info "Download link is: $download_link"
    prompt_user message="Do you wish to download this package and install it? [Y/n]: " \
        warning_message="The download link was gathered by an html scrapper, verify it's the accurate." \
        failure_message="You chose not to install iterm2 with the download link: $download_link" \
        success_message="" error_message="" exit_on_failure=false
    display_info "Downloading file from: $download_link"
    curl "$download_link" > "$filename"
    display_info "Unzipping: $filename into /Applications/"
    unzip "$filename" -d "/Applications/"
    return $?
}
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
#========================================================
#   Main Execution / Initialization
#========================================================
[[ $DEBUG == true ]] && display_debug "LIB-INSTALLERS: Loaded lib-installers.sh file"
return 0