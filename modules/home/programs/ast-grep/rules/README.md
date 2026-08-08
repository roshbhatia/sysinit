# Global ast-grep rules

Structural rules that apply to any repository, installed to
`~/.config/ast-grep/rules/` by `default.nix`. Run them with `sgg [PATH]`, which
is `ast-grep scan --config ~/.config/ast-grep/sgconfig.yml`. Inside a repository
that has its own `sgconfig.yml`, run plain `ast-grep scan` instead.

This repository's `sgconfig.yml` lists this directory as a second `ruleDirs`
entry, so `nix flake check` gates the Nix rules here against this checkout. The
repository-only rules live in `.ast-grep/rules/`.

## Admission rules

A rule earns a place here only if all three hold.

1. It is correct. The pattern was run against a fixture that should match and
   one that should not.
2. No dedicated linter already covers it. shellcheck, tsc, golangci-lint, and
   ruff run in their own gates; a rule that restates one of them just doubles
   the noise.
3. It is worth having in every repository, not just one.

A rule that carries `fix:` must produce compiling code. A `fix` that deletes the
thing it replaces is worse than no rule.

## What is here

| Rule | Severity | Catches |
| --- | --- | --- |
| `nix-with-scope` | error | `with lib;` / `with builtins;` |
| `nix-lib-via-pkgs` | error | `pkgs.lib.<fn>` instead of `lib.<fn>` |
| `nix-impure-eval` | error | `import <...>`, `builtins.getEnv`/`currentSystem`/`currentTime` |
| `ts-no-any`, `tsx-no-any` | error | `x: any`, `(): any`, `x as any` |
| `ts-no-type-suppression`, `tsx-…` | error | `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `eslint-disable` |
| `go-no-nolint` | error | `//nolint` |
| `go-errorf-wrap` | warning | `fmt.Errorf` with `%v` where `%w` wraps |
| `py-mutable-default-arg` | error | `def f(x=[])`, `={}`, `=set()` |
| `py-bare-except` | error | `except:` with no exception type |

Severity decides gating: `ast-grep scan` exits non-zero on an `error` rule and
zero on a `warning` one. `go-errorf-wrap` is a warning because `%v` on a
non-error argument is correct.

## What was removed and why

The previous version of this module carried eighteen rules. None ever ran, so
none had been tested. On review most were wrong rather than merely unused.

- `go-error-ignore` flagged `_, err := f()`, which is the normal Go idiom, so it
  fired on every error-returning call.
- `go-nil-check-before-len` advised a nil check before `len()`. `len(nil)` is 0
  and safe; the advice was incorrect.
- `go-context-first` used a leading `$$$`, which matches empty, so it also
  matched functions that already put `ctx` first.
- `no-console-log` carried `fix: "// TODO: Replace with proper logging"`, which
  replaces the statement with a comment and drops the arguments.
- `async-await` rewrote `p.then(cb)` to `await p`, discarding the callback.
- `shell-unquoted-variable` used `$$VAR`, where `$$` is ast-grep's own
  metavariable syntax, so the pattern did not mean what it read as.
- `shell-cd-without-check`, `shell-test-bracket`, `shell-set-errexit`, and
  `shell-command-substitution` duplicate shellcheck, which already gates every
  script in this repository.
- The five `k8s-*` rules matched on `containers:` three separate times, so a
  single manifest drew three overlapping diagnostics.

## Go patterns: a parser gotcha

`pkg.Func($ARG)` with exactly one argument does not match a Go call. Go's
grammar reads `errors.New(x)` as a `type_conversion_expression`, because the
same syntax converts to a qualified type. Two or more arguments parse as a
`call_expression` and match normally. Check `--debug-query=ast` before assuming
a Go pattern is wrong.
