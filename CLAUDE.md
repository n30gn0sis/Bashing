# CLAUDE.md

Guidance for AI assistants (and humans) working in this repository.

## What this project is

**Bashing** is a small Bash CLI toolkit. It provides a single executable,
`bin/bashing`, built on a set of sourced library modules in `lib/`, plus a
dependency-free test harness and lint/format tooling.

The repository was scaffolded as a starter project — the `greet` command is an
example placeholder meant to be replaced with real functionality. The library,
dispatch, test, and CI layers around it are real and working.

**Status:** v0.1.0. No `LICENSE` file yet — that is the repository owner's call,
so do not add one uninvited.

## Requirements

- **bash >= 4.2** — `lib/` uses associative arrays and `declare -g`.
  `bin/bashing` enforces this at startup with a clear error. macOS ships bash
  3.2, so contributors there need `brew install bash`.
- `git` (required at runtime by `bashing doctor` and by `scripts/shell-files.sh`)
- Optional: `shellcheck`, `shfmt` — needed for `make lint` / `make fmt` to do
  anything beyond a syntax check.

## Repository layout

```
bin/bashing            Executable entry point: global flag parsing + dispatch
lib/colors.sh          COLOR_* variables, TTY/NO_COLOR detection
lib/log.sh             Leveled logging to stderr (log::debug/info/warn/error)
lib/util.sh            Helpers: util::die/have/require_cmd/trim/join/confirm
lib/commands.sh        Subcommand implementations + BASHING_HELP descriptions
scripts/shell-files.sh Single source of truth for "which files are shell files"
scripts/lint.sh        bash -n on everything, then shellcheck if installed
scripts/fmt.sh         shfmt wrapper; --check mode for CI
scripts/test.sh        Thin wrapper around tests/run.sh
tests/run.sh           Dependency-free TAP-like test runner
tests/helpers.sh       assert_* helpers; sources lib/ for the tests
tests/test_*.sh        Test files, one per subject area
Makefile               Developer entry points; delegates to scripts/
.shellcheckrc          source-path=SCRIPTDIR so `source` directives resolve
.editorconfig          Mirrors the shfmt style (2-space, indented switch cases)
.github/workflows/ci.yml  Installs shellcheck+shfmt, runs lint/fmt-check/test
```

## Commands

Always go through `make` — CI runs the exact same targets, so a green `make
check` locally means a green CI.

```bash
make check       # lint + fmt-check + test — run this before every commit
make lint        # bash -n on all shell files, then shellcheck
make fmt         # reformat in place with shfmt
make fmt-check   # fail (with a diff) if anything is misformatted
make test        # run the full suite
make help        # list all targets
```

Run a single test file (much faster than the full suite when iterating):

```bash
scripts/test.sh tests/test_util.sh
```

There is no way to run a single test *function*; narrow to a file, or
temporarily rename the other `test_*` functions in it.

## Architecture

### Dispatch is by naming convention

`bin/bashing` parses global options, then maps the first non-option word to a
function: dashes become underscores, so `bashing my-thing` calls `cmd_my_thing`.
There is **no command registry to update** — defining the function is what
registers it.

`BASHING_HELP` (an associative array in `lib/commands.sh`) maps command name to
a one-line description. `bashing help` lists exactly the keys of that map, so a
command with a `cmd_*` function but no `BASHING_HELP` entry works but stays
hidden — which is the intended way to keep a command internal.

### Adding a subcommand

1. Define `cmd_<name>` in `lib/commands.sh`.
2. Add a `BASHING_HELP[<name>]` entry (keep the map alphabetical).
3. Optionally define `usage_<name>` for detailed help. Both `bashing help
   <name>` and the command's own `--help` print it.
4. Add tests to `tests/test_commands.sh`.

### Libraries are sourced, never executed

Every file in `lib/` is meant to be `source`d. Consequences to respect:

- **Do not put `set -euo pipefail` in `lib/`.** It belongs in `bin/bashing` and
  the `scripts/`. Setting it in a sourced file would silently change the
  caller's shell options.
- Each library starts with a **double-source guard** (`_BASHING_<NAME>_SH`).
  Keep this when adding a module.
- Load order matters: `colors.sh` → `log.sh` → `util.sh` → `commands.sh`.
  `log.sh` needs the `COLOR_*` variables; `util.sh` needs `log::error`.

### Naming conventions

- Library functions are namespaced with `::` — `log::info`, `util::die`.
- Internal helpers get a `_` after the namespace: `log::_emit`, `log::_enabled`.
- Subcommands are `cmd_<name>`; their detailed help is `usage_<name>`.
- Test functions must start with `test_` or the runner will not find them.
- Environment variables and globals are `BASHING_*` or `COLOR_*`.

### Output discipline

**All logging goes to stderr; only real results go to stdout.** This is what
makes `bashing <cmd> | other-tool` work. Tests enforce it — see
`test_log_writes_to_stderr_not_stdout`. When adding a command, print its result
with `printf` to stdout and use `log::*` for everything else.

`BASHING_LOG_LEVEL` is read on *every* log call rather than cached, so `-v` and
`-q` take effect regardless of flag order.

### Exit codes

Used consistently; tests assert on them, so keep them straight:

| Code | Meaning                                              |
| ---- | ---------------------------------------------------- |
| 0    | Success                                              |
| 1    | General runtime failure (`util::die` default)         |
| 64   | Usage error — bad/missing option, no command given   |
| 127  | Unknown command, or a required external tool missing |

## Testing

The runner is **pure bash — there is no bats, no external dependency.** Do not
add one without a strong reason; the suite must run on a bare clone.

How it works (`tests/run.sh`):

- Each test *file* runs in its own `bash` process, so files cannot leak state
  into each other.
- Each `test_*` function runs in its own subshell under `set -e`, so the first
  failed assertion ends that test and nothing after it runs.
- Output is TAP-like (`ok - name` / `not ok - name`); a non-zero exit means at
  least one test failed.

Assertions available from `tests/helpers.sh`: `assert_eq`, `assert_ne`,
`assert_contains`, `assert_not_contains`, `assert_success`, `assert_failure`,
`assert_status`.

Two things to know before writing tests:

- **`assert_success`/`assert_failure`/`assert_status` run their command in a
  subshell.** That is deliberate: helpers like `util::die` call `exit`, which
  would otherwise tear down the whole test instead of being observed as a
  status. Preserve this if you touch the helpers.
- `helpers.sh` sets `NO_COLOR=1` and `BASHING_LOG_LEVEL=silent` so assertions
  compare against stable strings. To test colored output, spawn a subshell with
  `BASHING_FORCE_COLOR=1` (see `test_force_color_emits_escape_sequences`).

Use `bashing_cli` from `helpers.sh` to invoke the CLI rather than hardcoding a
path.

## Style

Enforced mechanically by `make check` — run it rather than guessing.

- **Formatting:** `shfmt -i 2 -ci` (two-space indent, indented switch cases).
  Defined once in `scripts/fmt.sh`; `.editorconfig` mirrors it. Change both
  together or they drift.
- **ShellCheck must pass clean.** Fix findings properly instead of adding
  blanket `disable` directives. The few disables in the tree are narrow,
  single-rule, and carry a comment explaining why — match that bar. Note that a
  file-level `# shellcheck disable=` must appear *before the first command* in
  the file, otherwise it silently applies only to the next command.
- Quote expansions (`"$var"`, `"${arr[@]}"`); prefer `[[ ]]` over `[ ]`, and
  `$(...)` over backticks.
- Declare function-local variables with `local`.
- `readonly` for true constants (`BASHING_ROOT`, `BASHING_VERSION`).

## Gotchas

- **`scripts/shell-files.sh` only sees files git knows about** (tracked, plus
  untracked-and-not-ignored). A new script that is ignored by `.gitignore` will
  be silently skipped by lint and fmt.
- Extensionless files are picked up by **shebang sniffing**, which is how
  `bin/bashing` gets linted. A new `bin/` entry needs a `#!/usr/bin/env bash`
  line to be checked.
- `bin/bashing` resolves `BASHING_ROOT` by following symlinks, so `make install`
  (which symlinks into `/usr/local/bin`) works. Do not replace that resolution
  with a plain `dirname "$0"`.
- Missing `shellcheck`/`shfmt` is a **warning locally but a hard failure in
  CI**, where `BASHING_STRICT_TOOLS=1` is set. A clean local `make lint` does
  not prove CI will pass unless both tools are actually installed.
- CI does not currently test across bash versions. The 4.2 floor is enforced
  only by the runtime guard in `bin/bashing`, so a 4.2-incompatible construct
  would not be caught automatically.

## Git workflow

- Active development branch: `claude/claude-md-documentation-u8ihn9`.
- The repository has **no default branch yet** — it had zero commits before this
  scaffold.
- Run `make check` before committing; it is exactly what CI runs.
- Do not create pull requests unless explicitly asked.
