# Bashing

A small Bash CLI toolkit: one executable, a few sourced library modules, and a
dependency-free test harness.

This is a starter scaffold. The `greet` command is an example — replace it with
something real. Everything around it (dispatch, logging, tests, lint, CI) is
working and ready to build on.

## Requirements

- bash **4.2 or newer** (macOS ships 3.2 — `brew install bash`)
- `git`
- Optional, for development: [`shellcheck`](https://www.shellcheck.net/) and
  [`shfmt`](https://github.com/mvdan/sh#shfmt)

## Quick start

```bash
git clone https://github.com/n30gn0sis/Bashing.git
cd Bashing

./bin/bashing --help
./bin/bashing greet Ada
./bin/bashing doctor     # check your tooling
```

Install it onto your `PATH` (creates a symlink, so edits take effect immediately):

```bash
make install              # -> /usr/local/bin/bashing
make install PREFIX=~/.local
make uninstall
```

## Usage

```
usage: bashing [GLOBAL OPTIONS] <command> [ARGS...]

Global options:
  -h, --help        Show this help and exit
  -V, --version     Print the version and exit
  -v, --verbose     Log at debug level
  -q, --quiet       Log errors only
      --no-color    Disable colored output
      --            Stop parsing global options

Commands:
  doctor       Check that the development tooling is installed
  greet        Print a greeting (example command)
  help         Show usage for bashing or a single command
  version      Print the version and exit
```

Per-command help:

```bash
bashing help greet
bashing greet --help
```

### Environment variables

| Variable              | Effect                                            |
| --------------------- | ------------------------------------------------- |
| `BASHING_LOG_LEVEL`   | `debug`/`info`/`warn`/`error`/`silent` (def. info) |
| `NO_COLOR`            | Set to anything to disable color                  |
| `BASHING_FORCE_COLOR` | Set to `1` to force color when not a TTY          |
| `BASHING_ASSUME_YES`  | Set to `1` to auto-confirm prompts                |

Logs go to stderr, results to stdout — so `bashing <cmd> | other-tool` works.

## netcheck

`bin/netcheck` is a **standalone**, read-only network diagnostic for Ubuntu and
RHEL-family systems. It is self-contained — copy the single file to a host and
run it, no clone required.

```bash
scp bin/netcheck server:/tmp/ && ssh server /tmp/netcheck
```

```
netcheck  2026-08-15 17:58:22  (debian family)

  [ ok ] interfaces         eth0 up mtu=1400
  [ ok ] address            192.0.2.2
  [ ok ] gateway            192.0.2.1 via eth0
  [ ok ] gateway_reach      192.0.2.1 resolved in ARP cache (02:fc:00:00:00:05)
  [ ok ] egress             outbound TCP reachable (2/2 endpoints)
  [ ok ] dns_resolve        github.com resolved in 16ms
  [warn] nameserver_reach   no tcp/53 to 8.8.8.8 (udp may still work)
```

It **never modifies the host**. When something is broken it prints the
distro-appropriate fix command and leaves running it to you:

```
  [fail] gateway            no default route
         suggest: add a gateway in /etc/netplan/*.yaml, then: sudo netplan apply
```

On a RHEL box the same failure suggests `nmcli con mod <con> ipv4.gateway <ip>`
instead — the family is detected from `/etc/os-release`, including derivatives
like Rocky and Alma via `ID_LIKE`.

### Why it does not use `ip` or `ping`

Minimal cloud images routinely lack `ip`, `ping`, `dig`, and `nmcli` — a stock
Ubuntu 24.04 container has none of them. A diagnostic built on those tools
reports a total outage on a perfectly healthy machine. `netcheck` reads
`/proc` and `/sys` directly, resolves names via `getent`, and tests TCP with
bash's `/dev/tcp`, so the core checks have **no external dependencies**. When
`ip` or `nmcli` are present they are used for extra detail, never relied upon.

### Options

```
      --json           Emit results as JSON instead of a table
  -q, --quiet          Suppress output; rely on the exit code
      --target HOST    Hostname for the DNS check (default: github.com)
      --egress LIST    HOST:PORT list for the egress check
                       (default: 1.1.1.1:443,8.8.8.8:443)
      --timeout SECS   Per-probe timeout (default: 3)
      --no-color       Disable colored output
```

Exit codes: `0` all clear · `1` at least one check failed · `64` usage error.
Warnings and skips do not fail the run, so it drops straight into monitoring:

```bash
netcheck --quiet || alert "network degraded on $(hostname)"
netcheck --json | jq -r '.[] | select(.status=="fail")'
```

## Development

```bash
make check       # lint + fmt-check + test (what CI runs)
make lint        # bash -n, then shellcheck
make fmt         # reformat with shfmt
make test        # run the test suite
make help        # list all targets
```

Run one test file while iterating:

```bash
scripts/test.sh tests/test_util.sh
```

### Adding a command

1. Add `cmd_<name>` to `lib/commands.sh`.
2. Add a one-liner to the `BASHING_HELP` map.
3. Optionally add `usage_<name>` for detailed help.
4. Add tests to `tests/test_commands.sh`.

Dispatch is by naming convention, so there is no registry to update.

See [CLAUDE.md](CLAUDE.md) for the full architecture notes and conventions.

## Testing

Tests are plain bash — no bats, no dependencies. Each test file runs in its own
process and each `test_*` function in its own subshell, so failures stay
isolated.

## License

Not yet chosen.
