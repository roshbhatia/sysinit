## 1. Verification gate

- **SHAPE** loop
- **STOP** `nix flake check` exits 0 on the clean tree, and every check this
  phase adds fails when its defect is injected. Mutation is what puts a check the
  phase wrote outside its own blast radius. The CI job reporting on a pull
  request is a rollout task, not part of the exit
- **MAX-ITERS** 5

- [x] 1.1 Gather: list every zsh fragment `modules/home/programs/zsh/default.nix` interpolates, every `.lua` file under `modules/home/programs/wezterm/lua/`, and every `.sh` under `modules/home/programs/llm/config/` that no `writeShellApplication` wraps
- [x] 1.2 Act: add `checks.zsh-fragments-parse` running `zsh -n` (follows the hermetic `runCommand` shape at `flake.nix:229`); derive the file set from the directory, not a hand-written list
- [x] 1.3 Act: add `checks.wezterm-lua-parses` running a Lua front end in parse-only mode over `lua/**`
- [x] 1.4 Act: add `checks.llm-scripts-shellcheck` covering the unwrapped `.sh` files found in 1.1
- [x] 1.5 Act: extend `modules/lib/shell.nix` if the fragment list needs a shared accessor so the module and the check read one source
- [x] 1.6 Verify: run `nix flake check`; inject one syntax defect per check and confirm each fails and names the file; remove the defects
- [x] 1.7 Act: add `.github/workflows/check.yml` running `nix flake check` and one host build on push to `main` and on `pull_request`, with no path filter
- [x] 1.8 Act: reconcile `AGENTS.md` Commands with reality; either add the Taskfile or `devShells` that provide `task fmt:sh` and `task fmt:sh:check`, or remove those lines
- [x] 1.9 Verify: confirm every command in the `AGENTS.md` Commands section runs from a clean checkout
- [x] 1.10 Adversarial review (`adversarial-review` skill): critics attempt to break this slice against its spec scenarios, the design decisions, and the rollout gates
- [x] 1.11 Verify: `nix flake check` and `nh darwin build` green; review `git diff`
- [x] 1.12 Apply: commit and push the checks and the workflow file
- [ ] 1.13 Confirm: the workflow runs on the next pull request and its result is visible; if the Dependabot automation cannot merge a workflow change, the owner merges it manually

## 2. Guard fixtures and pattern reconciliation

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.destructive-guard-fixtures` exits
  0 both before and after the script consumes `destructiveDenyRegexes`, and
  removing any one pattern makes it fail
- **MAX-ITERS** 4

- [x] 2.1 Gather: record the effective pattern set of `claude-bash-guard.sh` beside `llmLib.allowlist.destructiveDenyRegexes`; name each of the differences (four are known)
- [x] 2.2 Act: write the fixture table pairing a command string with an expected decision; include the permitted forms `git push` and `git push origin main`, and a malformed-JSON fixture asserting fail-open
- [x] 2.3 Act: add `checks.destructive-guard-fixtures` running the guard scripts against the table (follows `flake.nix:229`)
- [x] 2.4 Verify: the fixture check passes against the current inlined patterns; record any fixture that only passes for one of the two pattern sets
- [x] 2.5 Act: decide each drifted pattern's reconciled form and record the decision in `design.md`; the stricter form wins unless the looser one is shown to be intentional
- [x] 2.6 Act: generate the guard script's pattern list from `destructiveDenyRegexes` at build time (follows the interpolation at `claude.nix:95`); remove the inlined regexes
- [x] 2.7 Act: apply the same generation to `codex-bash-guard`, which reads the same script file
- [x] 2.8 Verify: the fixture check still passes; no permitted form regressed to denied
- [ ] 2.9 Adversarial review (`adversarial-review` skill): critics attempt to break this slice against its spec scenarios, the design decisions, and the rollout gates. Review this slice hardest: it rewrites the only mechanical floor under the agent's Bash tool while `dangerouslySkipPermissions` is on
- [ ] 2.10 Verify: `nix flake check` and `nh darwin build` green; review `git diff` of the generated guard script text
- [ ] 2.11 Apply: `nh darwin switch`
- [ ] 2.12 Confirm: the owner runs one denied form and one permitted form through a live agent session and observes the expected outcome

## 3. WezTerm configuration containment

- **SHAPE** graph
- Not a loop: the exit is the owner watching a deliberately broken `ui.lua`
  degrade in a live WezTerm. Nothing can run that, so a STOP here would be a
  wish. The phase ends at its `Confirm:` task instead.

- [x] 3.1 Gather: inject a deliberate runtime error into `ui.lua` on the current configuration, start WezTerm, and record the observed behavior in `design.md`; the current fallback is an assumption, not a recorded fact
- [x] 3.2 Act: restructure `extraConfig` in `modules/home/programs/wezterm/default.nix` so `core.setup` runs first and unguarded, and `events`, `keybindings`, and `ui` each run under `pcall` `deps:` 3.1
- [x] 3.3 Act: add the failure report; name the module and carry the Lua error text; write to the WezTerm error log and to one channel the owner sees without opening that log `deps:` 3.2
- [x] 3.4 Verify: reproduce the injected error and confirm the shell, `PATH`, and key table survive and the failure is reported `deps:` 3.3
- [x] 3.5 Verify: confirm a failure in the reporting channel itself does not prevent the configuration from returning `deps:` 3.3
- [x] 3.6 Act: remove the injected error `deps:` 3.4,3.5
- [ ] 3.7 Adversarial review (`adversarial-review` skill): critics attempt to break this slice against its spec scenarios, the design decisions, and the rollout gates `deps:` 3.6
- [ ] 3.8 Verify: `nix flake check` and `nh darwin build` green; review `git diff` `deps:` 3.7
- [ ] 3.9 Apply: `nh darwin switch` `deps:` 3.8
- [ ] 3.10 Confirm: normal startup is unchanged; the owner reproduces the error once more on the switched system and observes containment `deps:` 3.9

## 4. WezTerm chord registry

- **SHAPE** graph

- [x] 4.1 Measure the real collision surface before building anything: canonicalize WezTerm's chords and compare against reserved chords, enabled symbolic hotkeys, and aerospace `deps:` none
- [x] 4.2 Move the chord vocabulary and data into `modules/darwin/lib/chords.nix` so the assertion and the check canonicalize identically `deps:` none
- [x] 4.3 Add `chordcheck/stub.lua` and `chordcheck/extract.lua`: load `keybindings.lua` headlessly and print canonical chords `deps:` 4.2
- [x] 4.4 Add `checks.wezterm-chord-collisions` comparing extracted chords against the other layers `deps:` 4.3
- [x] 4.5 Assert no WezTerm ALT chord, making aerospace collisions impossible by construction `deps:` 4.4
- [x] 4.6 Assert no duplicate chord across the seven binding groups `deps:` 4.4
- [x] 4.7 Verify: inject a duplicate, an unaccepted overlap, and an ALT chord; confirm each fails and names the chord; revert `deps:` 4.5, 4.6
- [x] 4.8 Verify: confirm the system derivation hash is unchanged by the refactor, proving no binding moved `deps:` 4.2
- [ ] 4.9 Adversarial review (`adversarial-review` skill): critics attempt to break this slice against its spec scenarios, the design decisions, and the rollout gates `deps:` 4.7, 4.8
- [ ] 4.10 Verify: `nix flake check` and `nh darwin build` green; review `git diff` `deps:` 4.9
- [ ] 4.11 Apply: `nh darwin switch` `deps:` 4.10
- [ ] 4.12 Confirm: the owner exercises one chord from each of the seven binding groups `deps:` 4.11

## 5. Agent state bus contract

- **SHAPE** graph

- [ ] 5.1 Write the JSON schema for the per-pane state file, covering the ten current fields plus an integer version `deps:` none
- [ ] 5.2 Add the version field to `agent-state.sh`; keep the emitter agent-agnostic, non-blocking, and always exit zero `deps:` 5.1
- [ ] 5.3 Add `checks.agent-state-schema` running the emitter against a fake tty for each reason source (`submit`, `tool`, `message`, literal) and validating the output (follows `flake.nix:229`) `deps:` 5.1, 5.2
- [ ] 5.4 Add a fixture whose reason contains quotes, backslashes, and newlines, and assert the output is still valid JSON `deps:` 5.3
- [ ] 5.5 Implement stale-entry collection in one place; it must remove nothing when the live pane set cannot be determined `deps:` 5.2
- [ ] 5.6 Package collection alongside the other `agent-*` scripts (follows `modules/home/programs/llm/config/notify.nix:77`) `deps:` 5.5
- [ ] 5.7 Verify: rename a field in the emitter without touching the schema and confirm the check fails and names the field; revert `deps:` 5.3
- [ ] 5.8 Verify: run collection while a live pane is mid-write and confirm the live entry survives and no reader observes a partial file `deps:` 5.5
- [ ] 5.9 Adversarial review (`adversarial-review` skill): critics attempt to break this slice against its spec scenarios, the design decisions, and the rollout gates `deps:` 5.7, 5.8
- [ ] 5.10 Verify: `nix flake check` and `nh darwin build` green; review `git diff` `deps:` 5.9
- [ ] 5.11 Apply: `nh darwin switch` `deps:` 5.10
- [ ] 5.12 Confirm: the statusline and the WezTerm session switcher both still render agent state for a live pane; a killed pane's entry is collected `deps:` 5.11

## 6. Sysinit doctor

- **SHAPE** graph

- [ ] 6.1 Add the `sysinit doctor` command skeleton with a probe registry and a non-zero exit when any probe reports drift (follows `modules/home/programs/llm/config/notify.nix:77`) `deps:` none
- [ ] 6.2 Add the generation probe: compare the running system generation against the built configuration `deps:` 6.1
- [ ] 6.3 Add the shell escape-hatch probe: list `~/.zshenv`, `~/.zshsecrets`, and `$XDG_CONFIG_HOME/zsh/extras/*`; report an unreadable file and continue `deps:` 6.1
- [ ] 6.4 Add the evalcache probe: report entries whose recorded source no longer resolves; do not delete `deps:` 6.1
- [ ] 6.5 Add the agent bus probe: count total, live, stale, and malformed state files; report a malformed file and continue `deps:` 6.1, 5.5
- [ ] 6.6 Add the WezTerm plugin probe: report a plugin path in `config.json` that does not resolve `deps:` 6.1
- [ ] 6.7 Verify: run on a clean machine and confirm exit zero; inject one drift per probe and confirm each is named and the exit code is non-zero `deps:` 6.2, 6.3, 6.4, 6.5, 6.6
- [ ] 6.8 Adversarial review (`adversarial-review` skill): critics attempt to break this slice against its spec scenarios, the design decisions, and the rollout gates `deps:` 6.7
- [ ] 6.9 Verify: `nix flake check` and `nh darwin build` green; review `git diff` `deps:` 6.8
- [ ] 6.10 Apply: `nh darwin switch` `deps:` 6.9
- [ ] 6.11 Confirm: `sysinit doctor` runs from a fresh shell and every probe returns `deps:` 6.10

## 7. Rollout

- [ ] 7.1 Verify: every slice is applied and confirmed; `nix flake check` green; the CI job is green on `main`
- [ ] 7.2 Apply: `git push` to `main`
- [ ] 7.3 Confirm: the CI job runs on `main` and passes
- [ ] 7.4 Verify: `openspec validate harden-agent-shell-terminal` and `specutil check` report no error findings
- [ ] 7.5 Apply: `openspec archive harden-agent-shell-terminal`
- [ ] 7.6 Confirm: the six capabilities appear under `openspec/specs/`; `openspec list` no longer shows the change as active
