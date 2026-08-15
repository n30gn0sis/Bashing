#!/usr/bin/env bash
# Tests for bin/netcheck.
#
# Every test runs against a fixture tree under tests/fixtures/, with the
# NETCHECK_*_ROOT seams pointed at it and NETCHECK_SKIP_NET=1. The suite
# therefore needs no network, no root, and no `ip`/`ping`/`dig`, and gives the
# same result on any machine.

# netcheck_fixture SCENARIO [ARGS...] — run netcheck against a fixture tree.
# Set NETCHECK_RESOLV_CONF_OVERRIDE to swap in a different resolv.conf.
netcheck_fixture() {
  local scenario=$1
  shift
  local root="$BASHING_ROOT/tests/fixtures/$scenario"

  NETCHECK_PROC_ROOT="$root/proc" \
    NETCHECK_SYS_ROOT="$root/sys" \
    NETCHECK_RESOLV_CONF="${NETCHECK_RESOLV_CONF_OVERRIDE:-$root/resolv.conf}" \
    NETCHECK_OS_RELEASE="$root/os-release" \
    NETCHECK_SKIP_NET=1 \
    NO_COLOR=1 \
    "$BASHING_ROOT/bin/netcheck" "$@"
}

# --- healthy systems ---------------------------------------------------------

test_ubuntu_healthy_passes() {
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "[ ok ] interfaces"
  assert_contains "$out" "[ ok ] gateway"
  assert_contains "$out" "0 fail"
  assert_status 0 netcheck_fixture ubuntu-healthy
}

test_rhel_healthy_passes() {
  local out
  out=$(netcheck_fixture rhel-healthy)
  assert_contains "$out" "[ ok ] interfaces"
  assert_contains "$out" "0 fail"
  assert_status 0 netcheck_fixture rhel-healthy
}

test_detects_debian_family() {
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "(debian family)"
}

test_detects_rhel_family_via_id_like() {
  # The fixture is ID=rocky, which must map to the rhel family via ID_LIKE.
  local out
  out=$(netcheck_fixture rhel-healthy)
  assert_contains "$out" "(rhel family)"
}

# --- parsing -----------------------------------------------------------------

test_gateway_decoded_from_proc_route() {
  # 0101A8C0 is little-endian for 192.168.1.1.
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "192.168.1.1 via eth0"
}

test_gateway_decoded_for_rhel_fixture() {
  # 0100000A is little-endian for 10.0.0.1.
  local out
  out=$(netcheck_fixture rhel-healthy)
  assert_contains "$out" "10.0.0.1 via ens192"
}

test_address_parsed_from_fib_trie() {
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "192.168.1.50"
}

test_address_excludes_loopback() {
  local out
  out=$(netcheck_fixture ubuntu-healthy --json)
  assert_not_contains "$out" "127.0.0.1"
}

test_address_is_deduplicated() {
  # fib_trie lists 192.168.1.50 in both the Main and Local tables.
  local out count
  out=$(netcheck_fixture ubuntu-healthy --json)
  count=$(printf '%s\n' "$out" | grep -c "192.168.1.50" || true)
  assert_eq "1" "$count" "address should appear once"
}

test_interface_mtu_reported() {
  local out
  out=$(netcheck_fixture rhel-healthy)
  assert_contains "$out" "mtu=9000"
}

test_gateway_reachability_from_arp_cache() {
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "[ ok ] gateway_reach"
  assert_contains "$out" "aa:bb:cc:dd:ee:01"
}

# --- failure scenarios -------------------------------------------------------

test_missing_gateway_fails() {
  local out
  out=$(netcheck_fixture no-gateway)
  assert_contains "$out" "[fail] gateway"
  assert_contains "$out" "no default route"
  assert_status 1 netcheck_fixture no-gateway
}

test_missing_gateway_suggests_distro_fix() {
  local out
  out=$(netcheck_fixture no-gateway)
  assert_contains "$out" "netplan apply"
}

test_missing_dns_fails() {
  local out
  out=$(netcheck_fixture no-dns)
  assert_contains "$out" "[fail] dns_config"
  assert_status 1 netcheck_fixture no-dns
}

test_interface_down_fails() {
  local out
  out=$(netcheck_fixture iface-down)
  assert_contains "$out" "[fail] interfaces"
  assert_contains "$out" "no interface is up"
  assert_status 1 netcheck_fixture iface-down
}

test_gateway_reach_skipped_without_route() {
  local out
  out=$(netcheck_fixture no-gateway)
  assert_contains "$out" "[skip] gateway_reach"
}

# --- warnings ----------------------------------------------------------------

test_excess_search_domains_warns_but_does_not_fail() {
  local out
  out=$(netcheck_fixture many-search)
  assert_contains "$out" "[warn] search_domains"
  assert_contains "$out" "7 search domains"
  assert_status 0 netcheck_fixture many-search
}

test_loopback_only_resolver_is_skipped_not_passed() {
  # A 127.0.0.53 stub proves nothing about upstream DNS, so claiming the
  # nameservers are reachable would be a false pass.
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "[skip] nameserver_reach"
}

test_systemd_resolved_stub_detected() {
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "systemd-resolved (stub)"
}

test_network_probes_skipped_not_failed() {
  # With NETCHECK_SKIP_NET=1 the egress check must skip, never fail.
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_contains "$out" "[skip] egress"
}

# --- output formats ----------------------------------------------------------

test_json_contains_expected_keys() {
  local out
  out=$(netcheck_fixture ubuntu-healthy --json)
  assert_contains "$out" '"check"'
  assert_contains "$out" '"status"'
  assert_contains "$out" '"detail"'
  assert_contains "$out" '"suggestion"'
}

test_json_is_parseable_when_python_available() {
  if ! command -v python3 >/dev/null 2>&1; then
    return 0
  fi
  local out
  out=$(netcheck_fixture no-gateway --json)
  printf '%s' "$out" | python3 -c 'import json,sys; json.load(sys.stdin)' ||
    t::fail "netcheck --json emitted invalid JSON"
}

test_json_exit_code_still_reflects_failure() {
  assert_status 1 netcheck_fixture no-gateway --json
}

test_quiet_suppresses_output_but_keeps_exit_code() {
  local out
  out=$(netcheck_fixture no-gateway --quiet)
  assert_eq "" "$out"
  assert_status 1 netcheck_fixture no-gateway --quiet
}

test_no_color_output_has_no_escape_sequences() {
  local out
  out=$(netcheck_fixture ubuntu-healthy)
  assert_not_contains "$out" $'\033'
}

# --- CLI ---------------------------------------------------------------------

test_help_exits_zero() {
  local out
  out=$("$BASHING_ROOT/bin/netcheck" --help)
  assert_contains "$out" "usage: netcheck"
  assert_success "$BASHING_ROOT/bin/netcheck" --help
}

test_version_prints_version() {
  local out
  out=$("$BASHING_ROOT/bin/netcheck" --version)
  assert_contains "$out" "0.1.0"
}

test_unknown_option_exits_64() {
  assert_status 64 "$BASHING_ROOT/bin/netcheck" --definitely-not-an-option
}

test_timeout_requires_a_number() {
  assert_status 64 "$BASHING_ROOT/bin/netcheck" --timeout abc
}

test_target_requires_a_value() {
  assert_status 64 "$BASHING_ROOT/bin/netcheck" --target
}

test_empty_resolv_conf_fails_cleanly() {
  # Pointing at a file with no nameserver must report a failure, not error out.
  local tmp out
  tmp=$(t::tmpdir)
  : >"$tmp/resolv.conf"
  out=$(NETCHECK_RESOLV_CONF_OVERRIDE="$tmp/resolv.conf" netcheck_fixture ubuntu-healthy)
  rm -rf "$tmp"
  assert_contains "$out" "[fail] dns_config"
}
