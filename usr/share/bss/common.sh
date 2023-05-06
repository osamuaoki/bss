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
PROG_VERSION="@@@VERSION@@@"
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
# System Functions (trap)
##############################################################################
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

