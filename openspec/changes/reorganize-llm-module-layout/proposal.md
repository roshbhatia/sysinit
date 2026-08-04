## Why

`modules/home/programs/llm/config/` holds 53 files with no organizing rule. One
directory carries eleven harness modules, ten scripts of the agent-agnostic
notification layer, two gates, two guard bodies, ten pi lockfiles, four pi
extension files, one opencode plugin, two cursor rule files, a Claude statusline,
and a Claude SessionEnd hook. Nothing in the path says which harness owns a file,
so the only way to learn that a script is pi-specific is to grep for its name.

The same flatness has already produced a live defect. `config/devin-guard.sh`
invokes the destructive-command guard by the bare name `claude-bash-guard`, but
devin builds that guard as `devin-bash-guard` and gemini builds it as
`gemini-bash-guard`. Neither name matches, so the lookup fails and the wrapper
exits 0. The devin and gemini exec guards deny nothing today. A guard body that
lived beside the harnesses that share it, rather than under a name claiming one
of them, would not have hidden this.

## What Changes

- Split `config/` into `harnesses/` and `runtime/`, then delete it. `harnesses/`
  holds one module per harness and nothing else. `runtime/` holds the
  agent-agnostic runtime every harness's hooks call: the desktop notifier, the
  per-pane state bus, the readiness report, the two gates, and the two guard
  bodies. The name contrasts with `lib/`, which runs at evaluation time.
- Move the two cross-harness output modules to the module root, beside the
  options they set: `acp.nix` writes the shared ACP registry, and
  `mcp-servers.nix` sets `sysinit.llm.mcp.additionalServers`, which
  `options.nix` declares. Neither is a harness, so neither belongs in
  `harnesses/`.
- Give each harness that owns assets its own directory, so the path names the
  owner: `harnesses/claude/`, `harnesses/cursor/`, `harnesses/gemini/`,
  `harnesses/opencode/`, `harnesses/pi/`. A harness with no asset stays one file.
- Colocate a skill's tool script with the skill, matching the layout every skill
  already uses for `references/` and `scripts/`. `citelock.sh` moves to
  `skills/citation-verification/`, and `wtrun.sh` moves to `skills/wtrun/`. The
  top-level `citation-tools/` directory goes away.
- Add `skill-tools.nix`, one module that builds the CLIs a skill owns from that
  skill's own directory. It replaces `citation-tools/default.nix` and takes the
  `wtrun` derivation out of the notifier module, which never had a reason to own
  it.
- Move `mcp.nix` to `lib/mcp-catalog.nix`, and move `skills.nix` to
  `skills/render.nix`. Both are the only remaining top-level files that shadow a
  directory of the same name.
- Fix the guard defect. The wrapper receives the guard's absolute path at build
  time, the way `runtime/` already injects `NOTIFY_EXE` and `SY_REAL`, so the
  lookup cannot depend on a name that is not on PATH. Add a flake check that
  feeds a destructive command to each wrapper and asserts a block.
- **BREAKING** for any out-of-tree reference to a path under
  `modules/home/programs/llm/config/`. Every in-tree reference is updated:
  `flake.nix`, `hack/update-pi.sh`, `AGENTS.md`, and the shipped cursor rule text.

### Non-goals

- Changing what any harness config produces. Every generated file keeps its
  content and its install path. This change moves sources only.
- Changing skill bodies, the skill registry format, or the frontmatter contract.
- Reorganizing `lib/` beyond the two file moves named above.
- Splitting `pi/default.nix`, which is 761 lines. Its size is a separate concern
  from where it sits.
- Adding, removing, or re-pinning a harness, a lockfile, or a vendored extension.
- Moving the agent-agnostic scripts under a skill. `loop-gate.sh` and
  `sy-gate.sh` are wired into harness hooks and the wezterm UI, so no single
  skill is their consumer.

## Behavior

- `nix flake check` exits 0 at the end of every phase.
- `find modules/home/programs/llm/config` reports no such directory when the
  change lands.
- The built home generation installs exactly the same set of file paths as it did
  before the change. No file appears and no file disappears. Compare a
  `nh darwin build` result path from before and after with `diff -r`. One content
  difference is expected and is the only one: the `citelock` binary carries a
  corrected usage comment, so its store path changes.
- No skill tree gains a copy of a script that a PATH package already provides.
  None of the four rendered trees contains `citelock.sh` or `wtrun.sh`. This is a
  prevention criterion, not a removal: neither script was ever installed into a
  skill tree, so the evidence for it MUST be that the new placement adds no entry
  to the installed set, and a check MUST fail if a later edit adds one.
- `citelock` and `wtrun` stay on PATH with their current interfaces. `citelock
  verify` on a directory with no lock exits 0, and `wtrun --status` exits 0.
- The flake's citation gate executes the moved `citelock.sh`, rather than only
  resolving its path. No change currently ships a `citations.lock`, so the gate's
  loop body never ran and the check passed on a path literal alone. It MUST carry
  fixtures: a directory with no lock exits 0, and a record missing its required
  fields exits non-zero.
- The devin exec guard and the gemini exec guard block a destructive command. A
  new flake check drives each assembled wrapper with hook JSON and asserts a
  non-zero exit for `git reset --hard`, `git push --force`, and `--no-verify`. It
  also asserts exit 0 for `ls -la` and `git status`, so the fix does not turn the
  guard into a deny-all. The commands MUST come from
  `lib/allowlist.nix`'s `destructiveDenyRules`, which is git-specific: asserting a
  block for `rm -rf` would test the fixture rather than the guard, because that
  table never claimed it.
- No file under `harnesses/` imports `lib/instructions.nix`,
  `lib/mcp-catalog.nix`, or `skills/render.nix` directly. `rg` over `harnesses/`
  for those three paths finds nothing outside `lib/harness-kit.nix`.
- No file under `lib/` reads a path inside `harnesses/`. `rg '\.\./harnesses'`
  over `lib/` finds nothing.
- Every moved file arrives unmodified unless a task says otherwise. `git diff
  -M --stat` reports a rename for each one.
- No reference to the old paths survives outside `openspec/`. Inside it, two sets
  are exempt and stay untouched: `openspec/changes/`, where the seven in-flight
  changes name the old paths as their own history, and `openspec/specs/`, which
  holds 8 such references across 6 files and is history under this schema. One
  consequence is accepted: the embedded verification command in
  `openspec/specs/harness-kit/spec.md` becomes unrunnable, which is what a frozen
  spec corpus means.
- The grep for that criterion MUST match a bare `config/<name>` and not only
  `llm/config/`. Prose in shipped content writes the short form, so a search
  anchored on `llm/` is blind to exactly the artifacts that teach an agent where
  to look. Three stale strings survived the first pass that way, one of them in
  `skills/worklog/SKILL.md`, which installs into four skill trees. The search MUST
  cover `modules/`, `AGENTS.md`, `hack/`, and `.githooks/`, and MUST exclude
  `.config/`, which is an XDG path and not a repository path.
- Shipped content that teaches a path is part of this change's surface, not
  incidental to it. That is every `SKILL.md`, every `.mdc` rule, every subagent
  definition, `AGENTS.md`, and any comment naming a module by path.

## Impact

Affected code:
- `modules/home/programs/llm/`: 56 files move, 1 file is deleted, 2 files are
  added, and 4 files are edited in place.
- `flake.nix`: 17 reference sites across 8 checks.
- `hack/update-pi.sh`: 5 path strings.
- `AGENTS.md` and the shipped `cursor/rules/nix.mdc`: the path text they teach.
- `modules/home/programs/zsh/integrations/seshy-wezterm.zsh` and
  `overlays/inputs.nix`: one comment each names the notifier module.
- `modules/darwin/home-manager.nix` and `modules/nixos/home-manager.nix` import
  `options.nix`, which does not move, so neither file changes.
- `openspec/specs/` is not touched. That directory is history under this schema,
  so rewriting its path strings would be ceremony.

Reuse:
- The per-harness directory follows the layout `skills/<name>/` already uses: a
  `default.nix` beside the assets it owns.
- `skill-tools.nix` follows `citation-tools/default.nix`, which it replaces.
- The build-time path injection in the guard fix follows `NOTIFY_EXE` in
  `runtime/agent-prompt.sh` and `SY_REAL` in `runtime/sy-gate.sh`.
- `harnesses/default.nix` follows the aggregating `imports` list already in
  `modules/home/programs/llm/default.nix`.

Progressive rollout:
- The change splits into five build-verifiable phases, listed in `tasks.md`. Each
  phase leaves `nix flake check` green, so any phase can land on its own.

Impactful and irreversible actions:
- `nh darwin switch` applies the result to the live Mac. It is the only impactful
  action here, and it runs once, in the Rollout phase.
- No `git push`, no network write, no vendored-content update, no schema change.
- Seven other changes are in flight and name the old paths in their task text.
  Their artifacts are not rewritten by this change. The Rollout phase records the
  path map so those changes can be read against it.

Gating signal:
- `nix flake check`, then `nh darwin build`, then `diff -r` of the old and new
  generation paths, then `nh darwin switch`. The kill switch is `git revert` of
  the phase commit, because every phase is a move plus a reference update with no
  state migration behind it.
