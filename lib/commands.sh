#!/usr/bin/env bash
# lib/commands.sh — subcommand implementations.
#
# Sourced, never executed. Requires colors.sh, log.sh and util.sh.
#
# Adding a subcommand:
#   1. Define `cmd_<name>`. Dashes in the CLI name map to underscores, so
#      `bashing my-thing` dispatches to `cmd_my_thing`.
#   2. Add a one-line description to BASHING_HELP below. `bashing help` builds
#      its command list from that map, so a command missing from it stays
#      hidden (useful for internal or experimental commands).
#   3. Optionally define `usage_<name>` for detailed help; `bashing help <name>`
#      and the command's own `--help` both print it.
#   4. Add a test in tests/test_commands.sh.
#
# Dispatch is by naming convention (see bin/bashing) — there is no registry to
# update.

[[ -n ${_BASHING_COMMANDS_SH:-} ]] && return 0
_BASHING_COMMANDS_SH=1

# Command name -> one-line description, shown by `bashing help`.
# Keep alphabetical; the listing is sorted by key.
# shellcheck disable=SC2034  # read by usage() in bin/bashing
declare -gA BASHING_HELP=(
  [doctor]="Check that the development tooling is installed"
  [greet]="Print a greeting (example command)"
  [help]="Show usage for bashing or a single command"
  [version]="Print the version and exit"
)

# --- help -------------------------------------------------------------------

usage_help() {
  printf 'usage: bashing help [COMMAND]\n'
}
cmd_help() {
  if (($# == 0)) || [[ $1 == -h || $1 == --help ]]; then
    usage
    return 0
  fi

  local name=$1
  local fn="cmd_${name//-/_}"
  local usage_fn="usage_${name//-/_}"

  if ! declare -F "$fn" >/dev/null 2>&1; then
    log::error "unknown command: $name"
    return 127
  fi

  printf '%s%s%s — %s\n\n' \
    "$COLOR_BOLD" "$name" "$COLOR_RESET" "${BASHING_HELP[$name]:-(no description)}"

  if declare -F "$usage_fn" >/dev/null 2>&1; then
    "$usage_fn"
  fi
}

# --- version ----------------------------------------------------------------

usage_version() {
  printf 'usage: bashing version\n'
}
cmd_version() {
  printf '%s\n' "$BASHING_VERSION"
}

# --- greet ------------------------------------------------------------------

usage_greet() {
  cat <<'EOF'
usage: bashing greet [-g GREETING] [NAME...]

Options:
  -g, --greeting TEXT   Greeting to use (default: Hello)
  -h, --help            Show this help

With no NAME, greets $USER.
EOF
}
cmd_greet() {
  local greeting="Hello" name

  while (($# > 0)); do
    case $1 in
      -g | --greeting)
        (($# >= 2)) || util::die "greet: --greeting requires a value" 64
        greeting=$2
        shift
        ;;
      -h | --help)
        usage_greet
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*) util::die "greet: unknown option: $1" 64 ;;
      *) break ;;
    esac
    shift
  done

  if (($# > 0)); then
    name=$(util::join ", " "$@")
  else
    name=${USER:-world}
  fi

  log::debug "greeting=$greeting name=$name"
  printf '%s, %s!\n' "$greeting" "$name"
}

# --- doctor -----------------------------------------------------------------

usage_doctor() {
  cat <<'EOF'
usage: bashing doctor

Reports which required and optional development tools are on PATH.
Exits non-zero if a required tool is missing.
EOF
}
cmd_doctor() {
  local -a required=(bash git)
  local -a optional=(shellcheck shfmt make)
  local tool status=0

  if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage_doctor
    return 0
  fi

  printf '%sbashing doctor%s\n' "$COLOR_BOLD" "$COLOR_RESET"
  printf '  root: %s\n' "$BASHING_ROOT"
  printf '  bash: %s\n' "$BASH_VERSION"
  printf '\n'

  for tool in "${required[@]}"; do
    if util::have "$tool"; then
      printf '  %s[ ok ]%s %-12s %s\n' \
        "$COLOR_GREEN" "$COLOR_RESET" "$tool" "$(command -v "$tool")"
    else
      printf '  %s[fail]%s %-12s not found (required)\n' \
        "$COLOR_RED" "$COLOR_RESET" "$tool"
      status=1
    fi
  done

  for tool in "${optional[@]}"; do
    if util::have "$tool"; then
      printf '  %s[ ok ]%s %-12s %s\n' \
        "$COLOR_GREEN" "$COLOR_RESET" "$tool" "$(command -v "$tool")"
    else
      printf '  %s[warn]%s %-12s not found (optional)\n' \
        "$COLOR_YELLOW" "$COLOR_RESET" "$tool"
    fi
  done

  return "$status"
}
