#!/usr/bin/env bash
# Tests for lib/util.sh.

test_trim_strips_surrounding_whitespace() {
  assert_eq "hello" "$(util::trim "   hello   ")"
  assert_eq "hello world" "$(util::trim $'\t hello world \n')"
}

test_trim_leaves_clean_strings_alone() {
  assert_eq "hello" "$(util::trim "hello")"
  assert_eq "" "$(util::trim "   ")"
}

test_join_single_item_has_no_separator() {
  assert_eq "a" "$(util::join ", " a)"
}

test_join_multiple_items() {
  assert_eq "a, b, c" "$(util::join ", " a b c)"
  assert_eq "a:b:c" "$(util::join ":" a b c)"
}

test_join_no_items_prints_nothing() {
  assert_eq "" "$(util::join ", ")"
}

test_have_detects_present_and_missing_commands() {
  assert_success util::have bash
  assert_failure util::have definitely-not-a-real-command-xyz
}

test_require_cmd_passes_when_present() {
  assert_success util::require_cmd bash
}

test_require_cmd_exits_127_when_missing() {
  assert_status 127 util::require_cmd definitely-not-a-real-command-xyz
}

test_die_exits_with_given_code() {
  assert_status 3 util::die "boom" 3
  assert_status 1 util::die "boom"
}

test_confirm_is_false_when_non_interactive() {
  assert_failure util::confirm "proceed?" </dev/null
}

test_confirm_honors_assume_yes() {
  BASHING_ASSUME_YES=1 assert_success util::confirm "proceed?"
}
