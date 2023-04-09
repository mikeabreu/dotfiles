# -----------------------------------------------
# Set Variables
# -----------------------------------------------
# Use this on macOS to prevent hitting delete key on empty terminal and closing it.
set -o ignoreeof
# This is being unset for compatability with multiple users running this theme
unset SPACESHIP_ROOT
# -----------------------------------------------
# Environment Variables
# -----------------------------------------------
export OLD_PATH="${PATH}"
export PATH="${HOME}/.local/bin:${PATH}:${HOME}/bin:"
export ZSH="/usr/share/oh-my-zsh"
export TERM="xterm-256color"
export GRC_DEBUG=false
export CLICOLOR_FORCE=1
# -----------------------------------------------
# Oh My ZSH Configuration
# -----------------------------------------------
declare ZSH_THEME="spaceship"
declare ZSH_TMUX_AUTOSTART="false"
declare ZSH_TMUX_AUTOSTART_ONCE="false"
declare -a plugins=(
    "git"
    "aws"
    "docker"
    "docker-compose"
    "docker-machine"
    "terraform"
    "tmux"
    "vscode"
    "python"
    "virtualenv"
    "nmap"
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
alias mkdir="/bin/mkdir -pv"
alias sudo='sudo '

alias ipconfig="ifconfig"
alias gipv4="grep -oE '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'"
alias gipv4r="grep -oE '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/[0-9][0-9]?'"
alias sipv4="sort -n -u -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4"
alias getips="gipv4 | sipv4"
alias getcidrs="gipv4r | sipv4"

alias show_all_colors='for code in {000..255};do print -P -- "$code: %F{$code}This is how your text would look like%f";done'
alias remove_color="sed -e 's/\[[0-9]\{2\}[;][0-9][;][0-9]\{1,3\}m//g' -e 's/\[0m//g' -e 's//g'"

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
function remove_color {
    sed -e 's/\[[0-9]\{2\}[;][0-9][;][0-9]\{1,3\}m//g' -e 's/\[0m//g' -e 's///g'
}
function command_exists {
    which "$1" &>/dev/null || command -v "$1" &>/dev/null
}
function ports {
    echo -e "${CTEAL}Listening ports:${CE}"
    [[ $(uname -a | awk '{print $1}') == "Darwin" ]] && {
        # macOS port check
        command_exists sudo && {
                sudo lsof -i -P | grep -i "listen"
        } || {  lsof -i -P | grep -i "listen"; }
    } || {
        # Non-macOS port check
        command_exists sudo && {
                sudo grc netstat -pntul
        } || {  grc netstat -pntul; }
        
    }
}
function connections {
    echo -e "${CTEAL}Established Connections:${CE}"
    [[ $(uname -a | awk '{print $1}') == "Darwin" ]] && {
        # macOS port check
        command_exists sudo && {
                sudo lsof -PiTCP
        } || {  lsof -PiTCP; }
    } || {
        # Non-macOS port check
        command_exists sudo && {
                sudo netstat -pantul | grep "ESTABLISHED"
        } || {  netstat -pantul | grep "ESTABLISHED"; }
    }
}
function ipx {
    [[ -z $1 ]] && {
        command_exists jq && {
                curl -s "ipinfo.io" | jq '.'
        } || {  curl -s "ipinfo.io" }
    } || {
        command_exists jq && {
                curl -s "ipinfo.io/${@}" | jq '.'
        } || {  curl -s "ipinfo.io/${@}" }
    }
}
function get_external_ip {
    echo -en "Method 0\tipinfo.io\t";curl -s http://ipinfo.io/ip
    echo -en "Method 1\tdns lookup\t";dig +short @resolver1.opendns.com myip.opendns.com
    echo -en "Method 2\tdns lookup\t";dig +short @208.67.222.222 myip.opendns.com
}
function crt_certs {
    curl -s https://crt.sh\?q\=%25.$1 |
        pup 'body table:last-child tbody tr json{}' |
            jq '.[].children | { logged_at: .[1].text, not_before: .[2].text, not_after: .[3].text, common_name: .[4].text, matching_identities: .[5].text, issuer: .[6].children[].text }' |
                jq -s '. | del( .[0])'
}
function checksums { echo -n "md5: ";md5sum "${@}";echo -n "sha1: ";sha1sum "${@}";echo -n "sha256: ";sha256sum "${@}";echo -n "sha512: ";sha512sum "${@}"; }
function mount_vmshare { vmhgfs-fuse .host:/ /mnt/host }
function docker_clean {
    command_exists grc && {
        for exited_container in $(grc --colour=off docker ps -a | grep "Exited" | awk '{print $1}'); do
            echo -n "${CTEAL}Removing container:${CE} "
            docker rm $exited_container
        done
    } || {
        for exited_container in $(docker ps -a | grep "Exited" | awk '{print $1}'); do
            echo -n "${CTEAL}Removing container:${CE} "
            docker rm $exited_container
        done
    }
}
function add_terminal_colors {
    # Reset Color
    CE="\033[0m"
    # Text: Common Color Names
    CT="\033[38;5;"
    CRED="${CT}9m"
    CGREEN="${CT}28m"
    CBLUE="${CT}27m"
    CTEAL="${CT}50m"
    CORANGE="${CT}202m"
    CYELLOW="${CT}226m"
    CPINK="${CT}13m"
    CPURPLE="${CT}63m"
    CLRED="${CT}196m"
    CLGREEN="${CT}46m"
    CLBLUE="${CT}45m"
    CLPINK="${CT}171m"
    CGRAY="${CT}240m"
    CWHITE="${CT}255m"
    # Text: All Hex Values: C0 - C255
    for HEX in {0..255};do eval "C$HEX"="\\\033[38\;5\;${HEX}m";done
    # Background: Common Color Names
    CB="\033[48;5;"
    CBRED="${CB}9m"
    CBGREEN="${CB}46m"
    CBBLUE="${CB}27m"
    CBORANGE="${CB}202m"
    CBYELLOW="${CB}226m"
    CBPINK="${CB}13m"
    CBPURPLE="${CB}63m"
    # Background: All Hex Values: CB0 - CB255
    for HEX in {0..255};do eval "CB${HEX}"="\\\033[48\;5\;${HEX}m";done
}
add_terminal_colors
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
[[ -f "/etc/grc/grc.zsh" ]] && source "/etc/grc/grc.zsh"
