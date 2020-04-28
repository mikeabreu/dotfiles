#============================
#   Dependency Check
#============================
REQUIRE_BASH_4_4=false
[[ $_LOADED_LIB_INSTALLERS == true ]] && [[ $DEBUG == true ]] &&
    display_debug "Duplicate source attempt on lib-installers.sh. Skipping source attempt." &&
    return 0
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
if [[ $_LOADED_LIB_DOTFILES == false ]];then
    if [[ -e lib-dotfiles.sh ]];then
        source lib-dotfiles.sh
    elif [[ -e "${HOME}/dotfiles/lib/lib-dotfiles.sh" ]];then
        source "${HOME}/dotfiles/lib/lib-dotfiles.sh"
    else
        echo "Missing lib-dotfiles.sh. Exiting."
        exit 1
    fi
fi
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
    command_exists brew && display_success "Package 'brew' is already installed. Skipping." && return 0
    display_info "Installing package manager 'brew' on the system."
    # /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" &&
        display_success "Package Manager brew has been successfully installed."
    return $?
}
function install_brew_bash {
    check_bash_version && display_success "Package 'bash' is already 4.4 of higher. Skipping." && return 0
    display_info "Installing package 'bash' with brew."
    brew install bash
    return $?
}
function install_brew_coreutils {
    command_exists timeout && 
        display_success "Package 'coreutils' is already installed. Skipping." && 
        return 0
    [[ $OPERATING_SYSTEM != "Darwin" ]] && 
        display_error "Unable to install package 'timeout'. Skipping." &&
        return 1
    # 'coreutils' is required for the use of 'timeout' in check_privileges. Mac OS Only
    display_info "Installing package 'coreutils' with brew."
    brew install coreutils && check_privileges
    return $?
}
#============================
#   Generic Installers       
#============================
function install_oh_my_zsh {
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
function install_spaceship_theme {
    # TODO: update this function
    if [[ -e "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
        display_warning "Skipping Installation: Spaceship (Already Installed)"
    else
        display_success "[+] Installing ZSH Theme:${CWHITE} Spaceship Prompt"
        copy_recursive "${CWD}/spaceship-prompt" "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt"
        ln -s "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "${HOME}/.oh-my-zsh/themes/spaceship.zsh-theme"
    fi
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
                display_warning "Unsupported Operating System version. Skipping."
                ;;
        esac
    fi
}

[[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && [[ $DEBUG == true ]] & 
    display_debug "lib-installers has functions that require bash 4.4+ and were not loaded" && return 1
[[ $REQUIRE_BASH_4_4 == true ]] && ! check_bash_version && [[ $DEBUG == false ]] && return 1
#============================
#   Bash 4.4+ Installers
#============================