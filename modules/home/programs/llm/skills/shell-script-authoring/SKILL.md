---
description: Write and validate Nushell automation and maintain existing shell scripts in sysinit and sysinit.laurel. Use for CLI wrappers, checks, hooks, and repository automation.
---

# Shell Scripting

## Choose the runtime

Use Nushell for new or substantially changed scripts in sysinit and
sysinit.laurel. Use the Nix-pinned `nu --no-config-file`, pass lists and
records between commands, and use JSON at external process boundaries when
the command offers it. Keep progress and errors on stderr when stdout is data.
Format with `nufmt` through the repository formatter and check the real script
with the declared dependencies from `nix develop`.

Keep the existing shebang and caller contract for a small Bash repair. Migrate
Python automation to Nushell. Document the blocker when conversion needs a
separate utility or library boundary.

## Bash scripts that remain

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `set -e` exits on error, `set -u` errors on undefined vars, `set -o pipefail`
  catches failures mid-pipe. Do not drop any of the three; each closes a class
  of silent failure.

## Quote every expansion: unquoted expansions word-split and glob

```bash
# good
cp "${src}" "${dst}"
rm -rf "${build_dir:?}"        # :? aborts if build_dir is empty/unset

# bad
cp ${src} ${dst}             # breaks the moment a path contains a space
rm -rf ${build_dir}/           # if build_dir is empty this is `rm -rf /`
```

Use `"${var:-default}"` for defaults. The `:?` and `:-` guards are why `set -u`
alone is not enough.

## Use `local` for every variable inside a function: globals leak across calls

```bash
# good
process() {
  local input="$1"
  local result
  result="$(transform "${input}")"
}

# bad
process() {
  result="$(transform "$1")"     # result is now global; the next caller inherits it
}
```

Declare and assign on separate lines when the value comes from a command, a
combined `local x="$(cmd)"` swallows the command's exit status.

## Output streams: diagnostics to stderr, data to stdout

```bash
# good
echo "ERROR: ${config} not found" >&2   # errors and progress go to stderr
echo "${resolved_version}"              # stdout carries only the script's output

# bad
echo "starting operation"                # progress on stdout pollutes $(...) captures downstream
```

A script whose stdout is consumed (`$(...)`, pipes, Taskfile deps) must keep
stdout pure data; prefix errors with `ERROR:` so failures grep out of CI logs.

## Clean up with a trap: manual cleanup is skipped on error exit

```bash
# good
cleanup() { rm -f "${tmpfile}"; }
trap cleanup EXIT                # runs even when set -e aborts mid-script

# bad
do_work
rm -f "${tmpfile}"             # never reached if do_work fails under set -e
```

## Formatting: `shfmt`, settings are fixed

Run `nix fmt` (writes) or `nix fmt -- --check` (verifies). The settings are
`shfmt -i 2 -ci -sr -s`: 2-space indent, indented case bodies, redirect operators
followed by a space, simplified. Preserve the permissions of sourced files.
Use the executable bit for scripts invoked directly.

## Validate

1. `nix fmt`, format.
2. `nix fmt -- --check`, verify formatting.
3. `nix flake check`, shellcheck runs over every script in the flake source.
4. Run the script and confirm it behaves.
5. Only report done once the check passes. Do not hand back unformatted or
   unrun scripts.
