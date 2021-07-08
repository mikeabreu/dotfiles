if [[ "$TERM" != dumb ]] && (( $+commands[grc] )) ; then
  # Prevent grc aliases from overriding zsh completions.
  setopt COMPLETE_ALIASES

  # Supported commands
  cmds=(
    "ant"
    "blkid"
    "configure"
    "cvs"
    "df"
    "diff"
    "dig"
    "dnf"
    "docker"
    "du"
    "env"
    "esperanto"
    "fdisk"
    "findmnt"
    "free"
    "gcc"
    "getfacl"
    "getsebool"
    "id"
    "ifconfig"
    "iostat_sar"
    "ip"
    "ipaddr"
    "ipneighbor"
    "iproute"
    "iptables"
    "irclog"
    "iwconfig"
    "last"
    "ldap"
    "log"
    "lolcat"
    "lsattr"
    "lsblk"
    "lsmod"
    "lsof"
    "lspci"
    "mount"
    "mtr"
    "mvn"
    "netstat"
    "nmap"
    "ntpdate"
    "php"
    "ping"
    "ping2"
    "proftpd"
    "ps"
    "pv"
    "semanageboolean"
    "semanagefcontext"
    "semanageuser"
    "sensors"
    "showmount"
    "sql"
    "ss"
    "stat"
    "sysctl"
    "systemctl"
    "tcpdump"
    "traceroute"
    "tune2fs"
    "ulimit"
    "uptime"
    "vmstat"
    "wdiff"
    "whois"
  );

  # Set alias for available commands.
  for cmd in $cmds ; do
    if (( $+commands[$cmd] )) ; then
      [[ $GRC_DEBUG == true ]] && {
        echo -e "remapping command for color: [alias \e[38;5;226m${cmd}\e[0m=\"grc --colour=auto ${cmd}\"], run [\e[38;5;1munset ${cmd}\e[0m] to remove alias."
      }
      alias $cmd="grc --colour=auto $cmd"
    fi
  done

  [[ $GRC_DEBUG == true ]] && echo -e "\e[38;5;3mChange [export GRC_DEBUG=true] to [export GRC_DEBUG=false] in your ~/.zshrc to disable these messages."

  # Clean up variables
  unset cmds cmd
fi
