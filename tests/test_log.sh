#!/usr/bin/env bash
# Tests for lib/log.sh and lib/colors.sh.

test_log_writes_to_stderr_not_stdout() {
  local out err
  out=$(BASHING_LOG_LEVEL=info log::info "hello" 2>/dev/null)
  err=$(BASHING_LOG_LEVEL=info log::info "hello" 2>&1 >/dev/null)
  assert_eq "" "$out" "stdout should stay clean"
  assert_contains "$err" "hello"
}

test_log_level_filters_lower_severities() {
  local err
  err=$(BASHING_LOG_LEVEL=warn log::info "quiet please" 2>&1 >/dev/null)
  assert_eq "" "$err"

  err=$(BASHING_LOG_LEVEL=warn log::error "loud" 2>&1 >/dev/null)
  assert_contains "$err" "loud"
}

test_log_level_debug_shows_everything() {
  local err
  err=$(BASHING_LOG_LEVEL=debug log::debug "details" 2>&1 >/dev/null)
  assert_contains "$err" "details"
}

test_log_level_silent_suppresses_everything() {
  local err
  err=$(BASHING_LOG_LEVEL=silent log::error "nope" 2>&1 >/dev/null)
  assert_eq "" "$err"
}

test_log_level_is_case_insensitive() {
  local err
  err=$(BASHING_LOG_LEVEL=WARN log::info "hidden" 2>&1 >/dev/null)
  assert_eq "" "$err"
}

test_log_includes_level_label() {
  local err
  err=$(BASHING_LOG_LEVEL=info log::warn "careful" 2>&1 >/dev/null)
  assert_contains "$err" "warn"
}

test_no_color_disables_escape_sequences() {
  local err
  err=$(NO_COLOR=1 BASHING_FORCE_COLOR=0 BASHING_LOG_LEVEL=info bash -c '
    source "$BASHING_ROOT/lib/colors.sh"
    source "$BASHING_ROOT/lib/log.sh"
    log::error "plain"
  ' 2>&1 >/dev/null)
  assert_contains "$err" "plain"
  assert_not_contains "$err" $'\033'
}

test_force_color_emits_escape_sequences() {
  local err
  err=$(BASHING_FORCE_COLOR=1 BASHING_LOG_LEVEL=info bash -c '
    unset NO_COLOR
    source "$BASHING_ROOT/lib/colors.sh"
    source "$BASHING_ROOT/lib/log.sh"
    log::error "fancy"
  ' 2>&1 >/dev/null)
  assert_contains "$err" $'\033'
}
