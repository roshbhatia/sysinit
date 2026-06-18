''
  # Shell Scripting

  Bash automation in this repo — `hack/` scripts, Taskfile commands, git hooks.
  These rules are prescriptive: each pairs the correct form with the failure it
  prevents. Apply them to every line you write or touch. When editing an existing
  script, match its surrounding style and apply these rules only to lines you change.

  ## Decision routing

  ```
  New script under hack/?       -> start from the boilerplate below, chmod +x, wire into Taskfile
  Editing an existing script?   -> apply rules only to lines you touch; keep its existing shape
  Need logging?                 -> source the logging library; do not echo (see Logging)
  Before reporting done?        -> run the validate loop until it passes (see Validate)
  ```

  ## Boilerplate — every script starts with exactly this

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```

  - `set -e` exits on error, `set -u` errors on undefined vars, `set -o pipefail`
    catches failures mid-pipe. Do not drop any of the three; each closes a class
    of silent failure.

  ## Quote every expansion — unquoted expansions word-split and glob

  ```bash
  # good
  cp "''${src}" "''${dst}"
  rm -rf "''${build_dir:?}"        # :? aborts if build_dir is empty/unset

  # bad
  cp ''${src} ''${dst}             # breaks the moment a path contains a space
  rm -rf ''${build_dir}/           # if build_dir is empty this is `rm -rf /`
  ```

  Use `"''${var:-default}"` for defaults. The `:?` and `:-` guards are why `set -u`
  alone is not enough.

  ## Use `local` for every variable inside a function — globals leak across calls

  ```bash
  # good
  process() {
    local input="$1"
    local result
    result="$(transform "''${input}")"
  }

  # bad
  process() {
    result="$(transform "$1")"     # result is now global; the next caller inherits it
  }
  ```

  Declare and assign on separate lines when the value comes from a command — a
  combined `local x="$(cmd)"` swallows the command's exit status.

  ## Log through the library, not `echo` — echo bypasses level control and formatting

  ```bash
  # good
  source "{{.LOGLIB_PATH}}"
  log_info "starting operation"
  log_warn "unexpected state, continuing"
  log_error "operation failed"

  # bad
  echo "starting operation"        # no level, no consistent format, no stderr routing
  ```

  ## Clean up with a trap — manual cleanup is skipped on error exit

  ```bash
  # good
  cleanup() { rm -f "''${tmpfile}"; }
  trap cleanup EXIT                # runs even when set -e aborts mid-script

  # bad
  do_work
  rm -f "''${tmpfile}"             # never reached if do_work fails under set -e
  ```

  ## Formatting — `shfmt`, settings are fixed

  Run `task fmt:sh` (writes) or `task fmt:sh:check` (verifies). The settings are
  `shfmt -i 2 -ci -sr -s`: 2-space indent, indented case bodies, redirect operators
  followed by a space, simplified. Do not pass other flags. All `.sh` files must be
  executable (`chmod +x`).

  ## File location

  | Type            | Path           |
  |-----------------|----------------|
  | Build scripts   | `hack/nix-*.sh`|
  | Format scripts  | `hack/fmt-*.sh`|
  | Utility scripts | `hack/*.sh`    |
  | Git hooks       | `.githooks/`   |

  ## Validate before done — loop until clean

  1. `task fmt:sh` — format.
  2. `task fmt:sh:check` — verify formatting.
  3. Run the script (or its `task` entry) and confirm it behaves.
  4. Only report done once the check passes. Do not hand back unformatted or
     unrun scripts.
''
