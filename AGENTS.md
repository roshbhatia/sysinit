# AGENTS.md

## Build, Lint, and Format Commands
- Use `task` for automation (see Taskfile.yml):
  - Format Nix: `task nix:fmt` (uses nixfmt)
  - Format Lua: `task lua:fmt` (uses stylua)
  - Build config: `task nix:build`
  - Apply config: `task nix:refresh`
  - Clean: `task nix:clean`
- No explicit test/lint commands; add tests to Taskfile.yml if needed.
- For shell scripts, ensure executability: `task sh:chmod`

## Code Style Guidelines
- **Imports:** Use local modules in Lua, overlays/modules in Nix, and source logger.sh in shell.
- **Formatting:** Enforce with nixfmt (Nix) and stylua (Lua). Shell scripts should be POSIX-compliant and readable.
- **Types:** Lua: prefer tables and functions; Nix: use lists/attrs; Shell: use key-value pairs for logs.
- **Naming:** Use lower_snake_case for Nix, local variables in Lua, and descriptive function names in shell.
- **Error Handling:**
  - Lua: use pcall for error-prone calls, notify on error.
  - Shell: use log_error/log_critical, exit on failure.
  - Nix: fail builds on error, use overlays for config.
- **Logging:** Use structured logging in shell (log_info, log_warn, etc.), include key-value pairs.
- **Config:** Deep merge configs in Lua, modularize Nix configs, keep shell scripts idempotent.

## Agent Notes
- No Cursor or Copilot rules present.
- If adding tests, update Taskfile.yml and document single-test execution.
- Keep AGENTS.md updated as conventions evolve.
