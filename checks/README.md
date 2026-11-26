# Repository checks

`default.nix` composes the agent, desktop, editor, host, package, shell, and
workflow suites. Each suite's `default.nix` exports its flake checks and calls
the probes in that directory. Use `nix build .#checks.<system>.<check>` for one
check or `nix flake check` for the host's full suite.

Use `lib/nushell.nix` for a Nushell probe and `lib/native.nix` for a sequence
of runtime probes. Declare a Nushell probe's relative imports in `sources` so
its store input contains just the probe and its dependencies. The native
runner creates an isolated home and XDG directories and copies declared
fixtures. Both runners use Nix-pinned runtimes.

Native probes retain the API they exercise:

| Runtime | Coverage |
| --- | --- |
| Lua and Neovim | Desktop integrations, editor APIs, language servers, and Tree-sitter |
| Emacs Lisp | Mail commands and rendering through ERT |
| JavaScript and TypeScript | Plugins through Bun and Node.js |
| Bash, Zsh, and Fish | Each shell's completion API |
| Python | PTYs, terminal emulation, asynchronous MCP stdio, and Unix WebSockets |

The [Python migration notes](../docs/python-migration.md) record the remaining
terminal and protocol probes. Use Nushell for ordinary filesystem and
configuration checks.

`pi-types` checks the managed Pi extensions against the published SDK and
Node runtime declarations. The source update workflow synchronizes the SDK
pins with the Pi release. For a local Pi update, run
`nix develop --command nu --no-config-file hack/update-pi-types.nu`.

`hack/lint.nu` runs semantic checks, including the Statix and Deadnix diagnostics
used by none-ls. `hack/format.nu --check` formats a temporary copy of tracked
files and leaves the checkout unchanged. Hooks and CI use `hack/lint.sh`.
