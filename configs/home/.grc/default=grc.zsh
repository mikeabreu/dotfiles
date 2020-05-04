[[ $_LOADED_GRC == true ]] && {
    [[ $DEBUG == true ]] && display_debug "Skipping: Duplicate source attempt on grc.zsh"
    return 0
}
declare _LOADED_GRC=true
if [[ "$TERM" != dumb ]] && (( $+commands[grc] )) ; then
  # Prevent grc aliases from overriding zsh completions.
  setopt COMPLETE_ALIASES

  # Supported commands
  cmds=(
    cat \
    less \
    tail \
    cc \
    configure \
    cvs \
    df \
    diff \
    dig \
    gcc \
    gmake \
    ip \
    ifconfig \
    last \
    ldap \
    lsof \
    make \
    mount \
    mtr \
    netstat \
    nmap \
    masscan \
    ping \
    ping6 \
    ps \
    traceroute \
    traceroute6 \
    wdiff \
  );

  # Set alias for available commands.
  for cmd in $cmds ; do
    if (( $+commands[$cmd] )) ; then
      alias $cmd="grc --colour=auto $cmd"
    fi
  done

  # Clean up variables
  unset cmds cmd
fi
