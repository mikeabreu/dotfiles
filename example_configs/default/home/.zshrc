# -----------------------------------------------
# Set/Unset Variables
# -----------------------------------------------
# This is being unset for compatability with multiple users running this theme
unset SPACESHIP_ROOT
# -----------------------------------------------
# Environment Variables
# -----------------------------------------------
export ORIG_PATH="${PATH}"
export GOPATH="${HOME}/gocode"
export GOBIN="${GOPATH}/bin"
export PATH="${PATH}:${HOME}/bin:${GOBIN}"
export ZSH="${HOME}/.oh-my-zsh"
export TERM="xterm-256color"
# -----------------------------------------------
# Oh My ZSH Configuration
# -----------------------------------------------
declare ZSH_THEME="spaceship"
declare ZSH_TMUX_AUTOSTART="false"
declare ZSH_TMUX_AUTOSTART_ONCE="false"
declare -a plugins=(
    "git"
    "tmux"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
)
[[ -r "${ZSH}/oh-my-zsh.sh" ]] && source "${ZSH}/oh-my-zsh.sh"

# -----------------------------------------------
# Aliases
# -----------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias lk="ls -lah *"
alias ll="ls -lh"
alias l="ls -lah"
alias cp="cp -av"
alias mv="mv -vf"
alias mkdir="mkdir -pv"
alias sudo='sudo '

alias ipconfig="ifconfig"
alias gipv4="grep -oE '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'"
alias gipv4r="grep -oE '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/[0-9][0-9]?'"
alias sipv4="sort -n -u -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4"
alias getips="gipv4 | sipv4"
alias getcidrs="gipv4r | sipv4"
alias show_all_colors='for code in {000..255};do print -P -- "$code: %F{$code}This is how your text would look like%f";done'

alias axel="axel -a"
alias header="curl -l"

alias sha1="openssl sha1"
alias md5="openssl md5"

alias rand512="dd if=/dev/urandom bs=64k count=1 2>/dev/null | sha512sum - | cut -d' ' -f 1"
alias rand256="dd if=/dev/urandom bs=64k count=1 2>/dev/null | sha256sum - | cut -d' ' -f 1"
alias rand64="dd if=/dev/urandom bs=64 count=1 2>/dev/null | base64 -w 96"
alias rand32="dd if=/dev/urandom bs=64k count=1 2>/dev/null | md5sum - | cut -c 1-8"
alias randmd5="dd if=/dev/urandom bs=64 count=1 2>/dev/null | md5sum - | cut -d' ' -f 1"

alias nmapp="nmap --reason --open --stats-every 3m --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit"
alias wgetasie7='wget -U "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 6.0; en-US)"'
alias wgetasie8='wget -U "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; .NET CLR 3.5.30729)"'

# -----------------------------------------------
# Functions
# -----------------------------------------------
function ports {
    echo -e "\033[38;5;50mListening ports:\033[0m"
    [[ $(uname -a | awk '{print $1}') == "Darwin" ]] && {
        # macOS port check
        sudo lsof -i -P | grep -i "listen"
    } || {
        # Non-macOS port check
        sudo netstat -pantul | grep "LISTEN"
    }
}
function ipx {
    if [ -z $1 ]; then
        curl "ipinfo.io"
    else
        curl "ipinfo.io/${@}"
    fi
}
function get_external_ip {
    echo -en "Method 0\tipinfo.io\t";curl -s http://ipinfo.io/ip
    echo -en "Method 1\tdns lookup\t";dig +short @resolver1.opendns.com myip.opendns.com
    echo -en "Method 2\tdns lookup\t";dig +short @208.67.222.222 myip.opendns.com
}
function checksums { echo -n "md5: ";md5sum "${@}";echo -n "sha1: ";sha1sum "${@}";echo -n "sha256: ";sha256sum "${@}";echo -n "sha512: ";sha512sum "${@}"; }
function docker_clean {
    for exited_container in $(docker ps -a | grep "Exited" | awk '{print $1}'); do
        echo -n "Removing docker container: "
        docker rm $exited_container
    done
}
function command_exists {
    which "$1" &>/dev/null || command -v "$1" &>/dev/null
}
# -----------------------------------------------
# Special Alias
# -----------------------------------------------
[[ $(uname -a | awk '{print $1}') == "Darwin" ]] && {
    # macOS Alias
    command_exists grc && {
            alias ls='grc ls -G'
    } || {  alias ls='ls -G';}
} || {
    # Non-macOS Alias
    command_exists grc && {
            alias ls='grc ls --color'
    } || {  alias ls='ls --color'; }
}
# -----------------------------------------------
# Sourcing
# -----------------------------------------------
# GRC Sourcing
[[ -f "${HOME}/.grc/grc.zsh" ]] && source "${HOME}/.grc/grc.zsh"
