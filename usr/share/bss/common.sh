## @brief bss common features
# vim:set ai si sts=2 sw=2 et:
# shellcheck disable=SC2004
# -- SC2004 disable globally due to dash weiredness
##############################################################################
# Copyright 2022 (C) Osamu Aoki <osamu@debian.org>
# License: GPL 2+
##############################################################################
#############################################################################
# Constants
#############################################################################
BSS_VERSION="1.2.4"
NOOP="" # set to ":" for no-operation
VERBOSE="" # set to "-v" for verbose (BSS_LOGGER_LEVEL=3,4)
SETX_ON="" # set to "set -x" for trace
SETX_OFF="" # set to "set +x" for trace
EXIT_SUCCESS=0
EXIT_ERROR=1
if [ "$(id -u)" = "0" ]; then
  SUDO=""
else
  if which sudo >/dev/null; then
    SUDO="sudo"
  else
    __echo 0 "Please install 'sudo' and configure it."
    exit $EXIT_ERROR
  fi
fi
#############################################################################
# System Functions (echo and trap)
##############################################################################
# v--- BSS_LOGGER_LEVEL
#   v--- SYSTEMD LOGGER_LEVEL
# 0 3 W:   Err       Print error
# 1 4 W:   Warning   Print warning        (-q)
# 2 5 N:   Notice    Print notice only    (normal)
# 3 6 I:   Info      Print verbose output (-v)
# 4 7 D:   Debug     Print Debug output   (-vv)
__echo () {
  $SETX_OFF
  BSS_MSG_LEVEL="$1"
  shift
  if [ "$BSS_LOGGER_LEVEL" -ge "$BSS_MSG_LEVEL" ]; then
    case $BSS_MSG_LEVEL in
      0) echo "E: $*" >&2
        ;;
      1) echo "W: $*" >&2
        ;;
      2) echo "N: $*" >&2
        ;;
      3) echo "I: $*" >&2
        ;;
      4|5|6|7) echo "D: $*" >&2
        ;;
    esac
    if [ "$BSS_LOGGER" = "1" ]; then
      case $BSS_MSG_LEVEL in
        0) systemd-cat -p 3 -t "bss" echo "$*"
          ;;
        1) systemd-cat -p 4 -t "bss" echo "$*"
          ;;
        2) systemd-cat -p 5 -t "bss" echo "$*"
          ;;
        3) systemd-cat -p 6 -t "bss" echo "$*"
          ;;
        4|5|6|7) systemd-cat -p 7 -t "bss" echo "$*"
          ;;
      esac
    fi
  fi
  $SETX_ON
}

# traps
__term_exit () {
  __echo 0 "Process externally interrupted.  Terminating $PROG_NAME."
  exit $EXIT_ERROR
}
trap '__term_exit' HUP INT QUIT TERM
# dash: EXIT (but no ERR)
__err_exit () {
  __echo 0 "Internal process returned an error exit.  Terminating $PROG_NAME."
  exit $EXIT_ERROR
}
__exit_exit () {
  # No error exit
  exit $EXIT_SUCCESS
}
trap '[ $? -eq 0 ] && __exit_exit || __err_exit' EXIT

