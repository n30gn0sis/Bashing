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
