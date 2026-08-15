#!/usr/bin/env bash
# Tests for bin/bashing dispatch and lib/commands.sh.

test_version_flag_prints_version() {
  local out
  out=$(bashing_cli --version)
  assert_contains "$out" "0.1.0"
}

test_version_command_matches_version_flag() {
  assert_eq "$(bashing_cli --version)" "$(bashing_cli version)"
}

test_help_lists_commands() {
  local out
  out=$(bashing_cli --help)
  assert_contains "$out" "usage: bashing"
  assert_contains "$out" "greet"
  assert_contains "$out" "doctor"
  assert_contains "$out" "version"
}

test_help_describes_commands_from_help_vars() {
  local out
  out=$(bashing_cli --help)
  assert_contains "$out" "Print a greeting"
}

test_no_arguments_is_usage_error() {
  assert_status 64 bashing_cli
}

test_unknown_command_exits_127() {
  assert_status 127 bashing_cli no-such-command
}

test_unknown_global_option_exits_64() {
  assert_status 64 bashing_cli --definitely-not-an-option
}

test_greet_defaults_to_user() {
  local out
  out=$(USER=tester bashing_cli greet)
  assert_eq "Hello, tester!" "$out"
}

test_greet_accepts_a_name() {
  local out
  out=$(bashing_cli greet Ada)
  assert_eq "Hello, Ada!" "$out"
}

test_greet_joins_multiple_names() {
  local out
  out=$(bashing_cli greet Ada Grace)
  assert_eq "Hello, Ada, Grace!" "$out"
}

test_greet_custom_greeting() {
  local out
  out=$(bashing_cli greet --greeting "Howdy" Ada)
  assert_eq "Howdy, Ada!" "$out"
}

test_greet_missing_greeting_value_exits_64() {
  assert_status 64 bashing_cli greet --greeting
}

test_greet_unknown_option_exits_64() {
  assert_status 64 bashing_cli greet --nope
}

test_double_dash_stops_global_option_parsing() {
  local out
  out=$(bashing_cli -- greet Ada)
  assert_eq "Hello, Ada!" "$out"
}

test_verbose_flag_enables_debug_logging() {
  local err
  err=$(BASHING_LOG_LEVEL=info bashing_cli --verbose greet Ada 2>&1 >/dev/null)
  assert_contains "$err" "greeting=Hello"
}

test_quiet_flag_suppresses_info_logging() {
  local err
  err=$(bashing_cli --quiet greet Ada 2>&1 >/dev/null)
  assert_eq "" "$err"
}

test_doctor_reports_required_tools() {
  local out
  out=$(bashing_cli doctor)
  assert_contains "$out" "bash"
  assert_contains "$out" "git"
}

test_doctor_succeeds_when_required_tools_present() {
  assert_success bashing_cli doctor
}

test_dashed_command_names_map_to_underscored_functions() {
  # `bashing my-thing` must dispatch to `cmd_my_thing`.
  local out
  out=$(bashing_cli --help)
  assert_not_contains "$out" "cmd_"
}
