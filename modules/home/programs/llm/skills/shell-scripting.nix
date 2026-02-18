''
  ---
  name: shell-scripting
  description: Use when writing or modifying shell scripts, particularly in the hack/ directory, Taskfile commands, or any bash automation
  ---

  # Shell Scripting

  ## Overview

  Shell scripts in this repo follow strict safety and formatting conventions. Most scripts live in `hack/` and are invoked via Taskfile.

  ## Required Boilerplate

  Every script must start with:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```

  - `set -e`: Exit on error
  - `set -u`: Error on undefined variables
  - `set -o pipefail`: Catch pipe failures

  ## Formatting

  - Tool: `shfmt`
  - Settings: `shfmt -i 2 -ci -sr -s -w`
    - `-i 2`: 2-space indent
    - `-ci`: Indent case bodies
    - `-sr`: Redirect operators followed by space
    - `-s`: Simplify code
  - Run: `task fmt:sh` (format) or `task fmt:sh:check` (verify)
  - All `.sh` files must be executable (`chmod +x`)

  ## Logging

  Scripts that use Taskfile integration should source the logging library:

  ```bash
  source "{{.LOGLIB_PATH}}"
  log_info "Starting operation"
  log_warn "Something unexpected"
  log_error "Operation failed"
  ```

  ## Variables

  - Use `local` for all variables inside functions
  - Quote all variable expansions: `"$${var}"`
  - Use `"$${var:-default}"` for defaults
  - Avoid global mutable state

  ## Error Handling

  - Check command success explicitly
  - Provide meaningful error messages
  - Use trap for cleanup:

  ```bash
  cleanup() {
    # cleanup logic
  }
  trap cleanup EXIT
  ```

  ## File Location

  | Type | Path |
  |------|------|
  | Build scripts | `hack/nix-*.sh` |
  | Format scripts | `hack/fmt-*.sh` |
  | Utility scripts | `hack/*.sh` |
  | Git hooks | `.githooks/` |

  ## Common Mistakes

  - Missing `set -euo pipefail`
  - Unquoted variable expansions
  - Missing executable permission on `.sh` files
  - Using `echo` for logging instead of `log_*` functions
  - Not using `local` in functions
''
