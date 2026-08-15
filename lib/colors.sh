#!/usr/bin/env bash
# lib/colors.sh — terminal color handling.
#
# Sourced, never executed. Defines COLOR_* variables and colors::init.
#
# Color is enabled only when stderr is a TTY. It is disabled when NO_COLOR is
# set (see https://no-color.org/) and forced on when BASHING_FORCE_COLOR=1,
# which is how the test suite exercises the colored code paths.

# The COLOR_* variables are this module's public API: they are read by log.sh
# and commands.sh, which ShellCheck cannot see when linting this file alone.
# shellcheck disable=SC2034

[[ -n ${_BASHING_COLORS_SH:-} ]] && return 0
_BASHING_COLORS_SH=1

# colors::enabled — succeeds when color output should be used.
colors::enabled() {
  [[ ${BASHING_FORCE_COLOR:-0} == 1 ]] && return 0
  [[ -n ${NO_COLOR:-} ]] && return 1
  [[ -t 2 ]]
}

# colors::init — (re)populate the COLOR_* variables for the current settings.
#
# Safe to call repeatedly; the CLI calls it again after parsing --no-color so
# that flag ordering does not matter.
colors::init() {
  if colors::enabled; then
    COLOR_RESET=$'\033[0m'
    COLOR_DIM=$'\033[2m'
    COLOR_BOLD=$'\033[1m'
    COLOR_RED=$'\033[31m'
    COLOR_GREEN=$'\033[32m'
    COLOR_YELLOW=$'\033[33m'
    COLOR_BLUE=$'\033[34m'
  else
    COLOR_RESET=''
    COLOR_DIM=''
    COLOR_BOLD=''
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
  fi
}

colors::init
