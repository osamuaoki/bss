# common log/echo handling
# IN:
# * PROG_NAME
# * BSS_LOGGER
# * BSS_LOGGER_LEVEL
# * NOOP
#
# OUT:
# * VERBOSE
# * LOGGER
# * __echo
# * __logger
#
#############################################################################
# System Variables (VERBOSE, LOGGER)
##############################################################################
case $BSS_LOGGER_LEVEL in
0)
  VERBOSE="-q"
  ;;
1)
  VERBOSE="-q"
  ;;
2)
  VERBOSE=""
  ;;
3)
  VERBOSE="-v"
  ;;
4)
  VERBOSE="-vv"
  ;;
5)
  VERBOSE="-vvv"
  ;;
6 | 7)
  VERBOSE="-vvvv"
  ;;
esac

if [ "$BSS_LOGGER" = "1" ]; then
  case $BSS_LOGGER_LEVEL in
    0) LOGGER="systemd-cat -p 3 -t $PROG_NAME"
      ;;
    1) LOGGER="systemd-cat -p 4 -t $PROG_NAME"
      ;;
    2) LOGGER="systemd-cat -p 5 -t $PROG_NAME"
      ;;
    3) LOGGER="systemd-cat -p 6 -t $PROG_NAME"
      ;;
    4|5|6|7) LOGGER="systemd-cat -p 7 -t $PROG_NAME"
      ;;
  esac
else
  LOGGER=""
fi
#############################################################################
# System Functions (__echo and __logger)
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
        0) systemd-cat -p 3 -t "$PROG_NAME" echo "$*"
          ;;
        1) systemd-cat -p 4 -t "$PROG_NAME" echo "$*"
          ;;
        2) systemd-cat -p 5 -t "$PROG_NAME" echo "$*"
          ;;
        3) systemd-cat -p 6 -t "$PROG_NAME" echo "$*"
          ;;
        4|5|6|7) systemd-cat -p 7 -t "$PROG_NAME" echo "$*"
          ;;
      esac
    fi
  fi
  $SETX_ON
}
__logger () {
  $NOOP $LOGGER "$@"
}
