#!/usr/bin/env bash
# lib/log.sh — leveled logging on stderr.
#
# Sourced, never executed. Requires lib/colors.sh to be sourced first.
#
# All log output goes to stderr so that a command's real output on stdout stays
# pipeable. The active level is read from BASHING_LOG_LEVEL on every call, so
# callers can raise or lower verbosity at any point without re-initializing.

[[ -n ${_BASHING_LOG_SH:-} ]] && return 0
_BASHING_LOG_SH=1

: "${BASHING_LOG_LEVEL:=info}"

# Numeric severities. Higher wins; `silent` suppresses everything.
declare -gA _BASHING_LOG_LEVELS=(
  [debug]=10
  [info]=20
  [warn]=30
  [error]=40
  [silent]=99
)

# log::_enabled LEVEL — succeeds when LEVEL is at or above the active level.
log::_enabled() {
  local want=${1,,} cur=${BASHING_LOG_LEVEL,,}
  local want_n=${_BASHING_LOG_LEVELS[$want]:-20}
  local cur_n=${_BASHING_LOG_LEVELS[$cur]:-20}
  ((want_n >= cur_n))
}

# log::_emit LEVEL COLOR MESSAGE... — internal formatter.
log::_emit() {
  local level=$1 color=$2
  shift 2
  log::_enabled "$level" || return 0
  printf '%s%-5s%s %s\n' "$color" "$level" "$COLOR_RESET" "$*" >&2
}

log::debug() { log::_emit debug "$COLOR_DIM" "$@"; }
log::info() { log::_emit info "$COLOR_BLUE" "$@"; }
log::warn() { log::_emit warn "$COLOR_YELLOW" "$@"; }
log::error() { log::_emit error "$COLOR_RED" "$@"; }

# log::success MESSAGE... — an info-level message styled as a positive result.
log::success() { log::_emit info "$COLOR_GREEN" "$@"; }
