# -----------------------------------------------
# Set Variables
# -----------------------------------------------
# Use this on macOS to prevent hitting delete key on empty terminal and closing it.
set -o ignoreeof
# -----------------------------------------------
# Environment Variables
# -----------------------------------------------
export OLD_PATH="${PATH}"
export GOPATH="${HOME}/gocode"
export GOBIN="${GOPATH}/bin"
export PATH="${PATH}:${HOME}/bin:${GOBIN}:/opt/X11/bin"
export ZSH="${HOME}/.oh-my-zsh"
export TERM="xterm-256color"
export EXE4J_JAVA_HOME="/usr/local/opt/openjdk/bin/"

# -----------------------------------------------
# Oh My ZSH Configuration
# -----------------------------------------------
ZSH_THEME='spaceship'
ZSH_TMUX_AUTOSTART='false'
ZSH_TMUX_AUTOSTART_ONCE='false'
plugins=( %%PLUGINS%% )
source "$ZSH/oh-my-zsh.sh"

# -----------------------------------------------
# Aliases
# -----------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls='ls -G'
alias lk="ls -lah *"
alias ll="ls -lh $@"
alias l="ls -lah $@"
alias cp="cp -av"
alias mv="mv -vf"
alias mkdir="/bin/mkdir -pv"
alias sudo='sudo '

alias ports="sudo lsof -PiTCP -sTCP:LISTEN +c0"
alias ipconfig="ifconfig $@"
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
# Function Libraries
# -----------------------------------------------

# -----------------------------------------------
# Functions
# -----------------------------------------------
ipx() {
    if [ -z $1 ]; then
        curl "ipinfo.io"
    else
        curl "ipinfo.io/${@}"
    fi
}
get_external_ip() {
    echo -en "Method 0\tipinfo.io\t";curl -s http://ipinfo.io/ip
    echo -en "Method 1\tdns lookup\t";dig +short @resolver1.opendns.com myip.opendns.com
    echo -en "Method 2\tdns lookup\t";dig +short @208.67.222.222 myip.opendns.com
}
crt_subdomains() { curl -s https://crt.sh\?q\=%25.$1 | awk -v pattern="<TD>.*$1" '$0 ~ pattern {gsub("<[^>]*>","");gsub(//,""); print}' | sort -u }
crt_certs() { curl -s https://crt.sh\?q\=%25.$1 | awk '/\?id=[0-9]*/{nr[NR]; nr[NR+1]; nr[NR+3]; nr[NR+4]}; NR in nr' | sed 's/<TD style="text-align:center"><A href="?id=//g' | sed 's#">[0-9]*</A></TD>##g' | sed 's#<TD style="text-align:center">##g' | sed 's#</TD>##g' | sed 's#<TD>##g' | sed 's#<A style=["a-z: ?=0-9-]*>##g' | sed 's#</A>##g' | sed 'N;N;N;s/\n/\t\t/g' }
crt_toCSV() {
    echo 'ID,Logged At,Identity,Issuer Name' > $1.csv
    curl -s https://crt.sh\?q\=%25.$1 | awk '/\?id=[0-9]*/{nr[NR]; nr[NR+1]; nr[NR+3]; nr[NR+4]}; NR in nr' | sed 's/<TD style="text-align:center"><A href="?id=//g' | sed 's#">[0-9]*</A></TD>##g' | sed 's#<TD style="text-align:center">##g' | sed 's#</TD>##g' | sed 's#<TD>##g' | sed 's#<A style=["a-z: ?=0-9-]*>##g' | sed 's#</A>##g' | sed 's/,/;/g' | sed 'N;N;N;s/\n/,/g' | sed 's/,[ ]*/,/g' | sed 's/^[ ]*//g' >> $1.csv
}
checksums() { echo -n "md5: ";md5sum "${@}";echo -n "sha1: ";sha1sum "${@}";echo -n "sha256: ";sha256sum "${@}";echo -n "sha512: ";sha512sum "${@}"; }
mount_vmshare() { vmhgfs-fuse .host:/ /mnt/host }
docker_clean() {
    for exited_container in $(docker ps -a | grep "Exited" | awk '{print $1}'); do
        echo -n "Removing container: "
	docker rm $exited_container
    done
}
# -----------------------------------------------
# Sourcing
# -----------------------------------------------
# GRC Sourcing
[[ -f "${HOME}/.grc/grc.zsh" ]] && source "${HOME}/.grc/grc.zsh"

# Google Cloud SDK Sourcing: path and completion
[[ -f "${HOME}/sdk/google-cloud-sdk/path.zsh.inc" ]] && source "${HOME}/sdk/google-cloud-sdk/path.zsh.inc"
[[ -f "${HOME}/sdk/google-cloud-sdk/completion.zsh.inc" ]] && source "${HOME}/sdk/google-cloud-sdk/completion.zsh.inc"

# OPAM Configuration
[[ -r "${HOME}/.opam/opam-init/init.zsh" ]] && source "${HOME}/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null || true