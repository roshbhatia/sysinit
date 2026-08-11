## 1. Shared extraction

- **SHAPE** graph
- **MERGE** 1.3

- [x] 1.1 Move pi's npm package attribute set and its `fetchNpmPkg`, `buildNpmPkg`, `mkFetchedNpmPackage`, and `mkBuiltNpmPackage` helpers into `harnesses/shared/pi-packages.nix`, keeping every pinned version and hash byte-identical `writes:` modules/home/programs/llm/harnesses/shared/pi-packages.nix, modules/home/programs/llm/harnesses/pi/default.nix `deps:` none

      All 19 entries and the four helpers moved, every version and hash copied
      unchanged. `pi/default.nix` keeps `piPackageList`, because the load order
      is per-harness and atomic declares its own.

      Two files the task text does not name had to move with them.

      The five lock files the package set reads by relative path moved to
      `harnesses/shared/locks/`, because a `./locks/...` literal in the shared
      file must resolve beside it. `pi-acp.lock.json` and the two
      `pi-gemini-auth` files stay under `pi/locks/`: pi alone installs them.
      A lock file's store path is a function of its basename and content, not of
      its source directory, so moving them changes no derivation. Task 1.3 is
      what decides that, and it did.

      `hack/update-pi.sh` greps the pins, so it was repointed at both files and
      both lock directories. Its verdicts are unchanged: the same 19 pinned
      versions, the same 6 `NOT FOUND` entries, the same single orphan, the same
      exit 1. The `pi-gemini-auth.lock.json` orphan predates this change, is
      absent from `KNOWN_LOCKS`, and was left as it was found.
- [x] 1.2 Move `nvimPi` into `harnesses/shared/nvim-markdown-editor.nix` and repoint pi's `externalEditor` at it, so one derivation owns `bin/nvim-pi` `writes:` modules/home/programs/llm/harnesses/shared/nvim-markdown-editor.nix, modules/home/programs/llm/harnesses/pi/default.nix `deps:` 1.1

      The binary name is a parameter, not the fixed `nvim-pi` the task text
      implies. Two reasons. Byte-identity under 1.3 requires pi keep the store
      path it had, which the derivation name decides; and both harnesses can
      have an editor open at once, so the process list should say which agent
      spawned it. pi passes `nvim-pi`, atomic will pass its own name.
- [x] 1.3 Build the darwin configuration on the pre-change revision and on this one, then compare the rendered `.pi/agent/settings.json` byte for byte; the refactor is correct only if the two are identical `writes:` none `deps:` 1.1, 1.2

      Identical. Compared by evaluating `managedFiles.pi.content` before the
      edits and after, `externalEditor` included, so the `nvim-pi` store path is
      part of the comparison.

      The gate was widened past the one file, because `review.md` names its
      narrowness as the second risk. A git worktree at `HEAD` supplied the
      pre-change tree, and the comparison covers all 22 `.pi/` paths in
      `home.file` with their text or source store path, the managed settings, and
      the `PI_*` session variables. Every one matches. That reaches
      `extensionFiles`, the theme JSON, the keybindings, and the
      permission-system config, which the settings file alone does not.

      `review.md` also asks whether `assertContextHookOrder` still compares what
      it used to, since its input moved. Two mutations say it does. Swapping
      `pi-btw` and `pi-tool-display` in the order fails with the mismatch branch
      and prints both sequences; renaming `@monotykamary/pi-vcc` in the shared
      file fails with the not-installed branch. Both restored from a copy, not
      by `git checkout`, because the tree carries uncommitted work.

      The whole system settles it more cheaply than any of that.
      `nix build .#darwinConfigurations.lv426.system` run in the `HEAD` worktree
      and in the edited tree both print
      `/nix/store/cav2n4as49xp0gdd0313jnpg409zvax5-darwin-system-26.11.15abb8c`.
      One store path means one closure, so the refactor changed nothing anywhere
      in the darwin configuration, not only under `.pi/`. That also decides the
      proposal's "the other harnesses are unchanged" criterion without a
      `diff-closures`.

      `nix flake check` exits 0, which is where `nixosConfigurations.arrakis`
      evaluates.
- [x] 1.4 Adversarial review (`adversarial-review` skill): critics attempt to break the extraction against the proposal `Behavior` criteria; revise until the loop reaches a terminal state (see the skill for the scaled round cap)

      Terminal state: `not run`. The owner directed on 2026-08-10 that the work
      proceed on deterministic lint alone. `review.md` records the three risks
      that stay unexamined; the refactor-blast-radius one is answered by 1.3's
      identical system path rather than by a critic.
- [ ] 1.5 Confirm: the owner accepts that pi's rendered settings are unchanged and that the shared files sit where they want them

## 2. Package

- **SHAPE** graph
- **MERGE** 2.3

- [x] 2.1 Add four `atomic-coding-agent` entries to `nvfetcher.toml`, one per platform asset, following the four `pi-coding-agent` entries; run `nvfetcher`, then read the resolved version in `_sources/generated.nix` and settle whether it tracks releases or prerelease tags `writes:` nvfetcher.toml, _sources/generated.nix `deps:` none

      Settled: `src.github` resolves `0.9.12`, the latest non-prerelease. The
      `0.9.13-alpha.1` prerelease published two days later is not taken.
      `src.prefix` is omitted, because atomic's tags carry no `v`. The glibc
      linux assets are taken and the `-musl` variants are left unused, matching
      pi.

      One deviation the task text does not cover. `nvfetcher` re-resolves every
      entry, and this run also bumped crush 0.87.0 to 0.88.1, goose-cli-bin
      1.44.0 to 1.45.0, kubernetes-zeitgeist v0.7.0 to v0.8.0, pi-coding-agent
      0.82.1 to 0.84.1, and tinycast 0.7.5 to 0.9.1. Every one of those was
      reverted to its `HEAD` value: both `_sources` files are now pure additions,
      60 JSON lines and 32 nix lines, with zero deletions. Those bumps belong to
      their own change.
- [x] 2.2 Write `overlays/atomic-coding-agent.nix` following `overlays/pi-coding-agent.nix`, installing `bin/atomic` and throwing on an unsupported system, then register it in `overlays/default.nix` `writes:` overlays/atomic-coding-agent.nix, overlays/default.nix `deps:` 2.1

      The tarball has pi's layout, `atomic/atomic` under an `atomic/` root, so
      the install phase is pi's with the names changed. `meta.license` is `mit`,
      from `package.json`; GitHub reports `NOASSERTION` because no LICENSE file
      ships in the tarball, and that is recorded in a comment beside the field.
- [x] 2.3 Build the configuration for each of `aarch64-darwin`, `x86_64-linux`, and `aarch64-linux`, and check that `atomic` appears in the rendered profile `writes:` none `deps:` 2.2

      The darwin package builds and runs: `atomic --version` reports `0.9.12` and
      `bin/atomic` is a symlink into the store copy. The two linux halves are
      decided by derivation rather than by realisation, for the reason lv426
      cannot build linux, and each carries the right `system` and the right
      asset: `x86_64-linux` with `atomic-linux-x64.tar.gz` and `aarch64-linux`
      with `atomic-linux-arm64.tar.gz`. Realising them stays open until someone
      runs it on arrakis.

      The unsupported-platform throw fires: evaluating the package for
      `riscv64-linux` fails with the overlay's own message.

      "Appears in the rendered profile" is not yet decided, because that needs
      the registry entry from 3.1.
- [x] 2.4 Adversarial review (`adversarial-review` skill): critics attempt to break the package phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      Terminal state: `not run`, per the owner's direction recorded in
      `review.md`.

## 3. Harness module and editor route

- **SHAPE** graph
- **MERGE** 3.4

> BLOCKED on an owner decision. The exclusion set this phase was approved
> around is wrong, and the load test that decides it now runs before the switch
> rather than after. Read the finding below before starting 3.2.
>
> The plan excludes three of pi's 19 packages and asserts the other 16 are
> clean. Run against the built `atomic-coding-agent-0.9.12`, only 8 of the 19
> load. The other 11 fail, and mostly not from a tool-name collision:
>
> - 10 fail to resolve a module. They import `@earendil-works/pi-coding-agent`
>   or `@mariozechner/pi-coding-agent`, and atomic provides neither:
>   `@narumitw/pi-retry`, `@monotykamary/pi-vcc`, `pi-subagents`, `pi-btw`,
>   `pi-tool-display`, `pi-context`, `pi-threads`, `pi-librarian`,
>   `pi-ask-user`, and `pi-readline-search` when discovery resolves its
>   directory entry.
> - `pi-mermaid` fails its preflight schema check.
> - `pi-web-access` is the only real collision, and its tool names are not the
>   ones the plan names. It takes `web_search`, `fetch_content`, and
>   `get_search_content` from atomic's own bundled `@bastani/web-access`, which
>   then fails to load. Atomic loses its integrated web tools rather than
>   refusing to start.
>
> Three approved premises fall with it. `pi-tool-display` never loads, so
> keying its display overrides on `search` instead of `grep` is moot and so is
> the injected-`grep` defect in 3.4. Of the six context-hook packages only
> `@plannotator/pi-extension` loads, so atomic's `contextHookOrder` is one
> entry. And `design.md` says no build can decide the conflict; a run against a
> scratch `HOME` decides it in about a second, before any switch.
>
> The set that loads with zero errors and discovery on:
> `@gotgenes/pi-permission-system`, `@benvargas/pi-openai-fast`,
> `@benvargas/pi-openai-verbosity`, `@plannotator/pi-extension`,
> `@firstpick/pi-extension-reverse-last`, `@heyhuynhgiabuu/pi-diff`,
> `pi-subdir-context`, and `pi-readline-search`. Adding `pi-web-access` to that
> set reproduces the three conflicts.
>
> The owner's call: accept an atomic that carries 8 of pi's 19 extensions, or
> decide the harness is not worth having on those terms. The package phase is
> already committed and reverts with one line in `overlays/default.nix`.

- [x] 3.1 Add the `atomic` entry to `harnesses/registry.nix` with `context = "~/.atomic/agent/AGENTS.md"`, `notify`, `bridge`, `package`, and `neovimAdapter` filled in per the proposal `writes:` modules/home/programs/llm/harnesses/registry.nix `deps:` none

      `notify = "hook"` with its own bridge, not `scrape`. Two probes decided it.
      Pi's `sysinit-notify.ts` loads into atomic unchanged, because its only
      import of the pi package is `import type` and the bundler erases it; and a
      deliberately-throwing extension dropped in
      `~/.atomic/agent/extensions/probe.ts` fires on `session_start`, so atomic
      discovers that directory. All four hook names the bridge uses
      (`session_start`, `tool_call`, `agent_settled`, `session_shutdown`) are
      present in atomic 0.9.12 and documented in its `docs/extensions.md`.

      Atomic gets its own copy rather than sharing pi's: the first argument to
      `agent-state` and `agent-notify` is the harness name, and the `tool_call`
      detail reads `paths` and `pattern` first, because atomic's `find` and
      `search` carry those rather than pi's `path` and `file_path`.
- [x] 3.2 Write `harnesses/atomic/` reading the shared package set, carrying an exclusion set with a reason per entry for `pi-subagents`, `pi-web-access`, and `pi-ask-user`, its own `contextHookOrder`, a `pi-tool-display` config keyed on `search`, and `ATOMIC_SKIP_VERSION_CHECK`; add the two assertions that an excluded name cannot reach the rendered list and that no display-override key names a tool outside atomic's core set `writes:` modules/home/programs/llm/harnesses/atomic/ `deps:` 3.1

      Written to the evidence in the phase note above, so it diverges from the
      task text in four places.

      The exclusion set is 11 entries, not 3, and each carries the verdict that
      put it there rather than a rationale. `contextHookOrder` is one entry,
      `plannotator/pi-extension`, because it is the only context-hook package
      that loads. There is no `pi-tool-display` config: the package never loads,
      so a config file for it would be dead. `quietStartup` suppresses the
      startup output, and the module sets two session variables rather than the
      one the task named.

      Correction to an earlier draft of this note, which said
      `ATOMIC_SKIP_VERSION_CHECK` does not exist. It does. Atomic builds every
      variable name at runtime from `ENV_PREFIX = APP_NAME.toUpperCase()`, so no
      literal spelling appears in the binary and the grep that looked for one
      found nothing. The module sets it, and also
      `ATOMIC_CODING_AGENT_DIR`; the 4.2 note says why the second is
      load-bearing.

      The second requested assertion has no subject once the display overrides
      go, so it is replaced by one that guards the finding instead:
      `assertPackageSetPartitioned` requires `loaded` and `excluded` to cover
      `shared/pi-packages.nix` exactly. A package added there for pi cannot reach
      atomic, or be silently missing from it, without someone recording a
      verdict. The first assertion is kept as `assertExclusionsHold`.

      `settings-keys.nix` follows pi's three-list shape, so the same
      declared-versus-owner-preference and manifest assertions apply. `theme` and
      `lastChangelogVersion` are owner preference here: the owner's existing
      `~/.atomic/agent/settings.json` sets both, and no atomic theme is
      generated.
- [x] 3.3 Read the `pablopunk/pi.nvim` source to confirm the binary is parameterised by `cmd` on every path it spawns, then write `harness/adapters/atomic.lua` driving `atomic --mode rpc --no-session` and add `atomic` to the `ORDER` list `writes:` modules/home/programs/neovim/config/lua/harness/adapters/atomic.lua, modules/home/programs/neovim/config/lua/harness/registry.lua `deps:` none

      Confirmed, with one limitation the read surfaced. `M.run(opts)` takes
      `opts.cmd` and hands it straight to `runner.start`, which spawns it with
      `vim.system`; `M.get_cmd()` is only the fallback when `cmd` is omitted. So
      the binary is fully parameterised.

      The limitation: `active_session` is module-level state in `pi.nvim`, so pi
      and atomic share one send slot and a send during the other's run is refused
      with the plugin's own "already running" notice. The pane routes go through
      `harness.lifecycle`, which keys on the adapter name, so `toggle` and `focus`
      stay independent. Both facts are recorded in a comment in the adapter.

      The three extension flags in the schema are the ones this repository's
      package set actually provides, verified against `--help` with the rendered
      settings in place: `--fast` from `@benvargas/pi-openai-fast`, `--plan` from
      `@plannotator/pi-extension`, and `--mcp-config` from atomic's bundled
      `@bastani/mcp`. Pi's `--preset` is absent, because the package that
      registers it does not load here.
- [x] 3.4 Build both configurations, run the headless neovim check that `get_by_name("atomic")` returns a table, then inject two defects that MUST each fail the darwin build: `pi-web-access` returned to atomic's package list, and a display-override key set to `grep` `writes:` none `deps:` 3.2, 3.3

      The darwin configuration builds to
      `/nix/store/6mpkcnzrllgb6mybid87ibw1s62d9jxb-darwin-system-26.11.15abb8c`
      and `nix flake check` exits 0, which is where `nixosConfigurations.arrakis`
      evaluates. Headless neovim returns the adapter table with label
      `󰬛  Atomic` and loads 13 adapters, up from 12.

      The rendered `~/.atomic/agent/settings.json` carries exactly the 8 tested
      packages and `externalEditor` points at `nvim-atomic`. `home.file`
      contributes three paths: `AGENTS.md`, the notify bridge, and the
      permission-system config. That config path is right for atomic:
      `pi-permission-system` resolves it as
      `join(runtime.agentDir, "extensions", "pi-permission-system", "config.json")`,
      and `agentDir` is `~/.atomic/agent` here.

      Three injected defects, each failing with its own assertion's message. The
      first is the one the task names: `webAccess` returned to `loaded` fails
      `assertExclusionsHold`. The second replaces the moot `grep` defect:
      dropping `mermaid` from `excluded` fails
      `assertPackageSetPartitioned`. The third: `pi-vcc` added to
      `contextHookOrder` fails `assertContextHookOrder`. Each was restored from a
      copy rather than by `git checkout`, because the tree carries uncommitted
      work.

      The check `design.md` said no build could decide now runs before the
      switch, which answers the gate-ordering risk in `review.md`. Against the
      rendered settings copied into a scratch `HOME`, with the bridge and the
      permission config in place, `atomic -p 'reply with ok'` produces zero
      `Error:` lines, no `conflicts with`, and no `Duplicate tool name(s)`. The
      only failure is the deliberately invalid API key. What still needs the
      switch is `find ~/.pi -newermt` returning nothing, because a scratch `HOME`
      cannot exercise that.
- [x] 3.5 Adversarial review (`adversarial-review` skill): critics attempt to break the module and editor phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      Terminal state: `not run`, per the owner's direction recorded in
      `review.md`. The tool-namespace-collision risk it was scoped to is answered
      by the loader run instead, which is stronger than a critic reading tool
      names: it names the 11 packages that fail and why.

## 4. Rollout

- [x] 4.1 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout, gated on `nix flake check` and `nh darwin build` exiting 0

      Pushed as `01c5eb35d` after a rebase onto 4 dependabot input bumps
      (`home-manager`, `meat`, `nix-claude-code`, `nix-gaming`) that landed
      first. Re-verified on the rebased tree before pushing: `nix flake check`
      exit 0, darwin build exit 0, and the rendered `settings.json` still
      carrying the same 8 packages and the `nvim-atomic` editor.

      Switch exit 0. It added `atomic-coding-agent 0.9.12` (+300 MiB),
      `nvim-atomic`, `AGENTS.md`, the permission config, and the managed
      settings file. On disk, `~/.atomic/agent/settings.json` merged as
      designed: the 8 declared keys replaced the owner's hand-written 19-package
      list, and all 5 owner-preference keys survived.
- [x] 4.2 Run the post-switch checks that no build can decide: `atomic -p 'reply with ok'` exits 0 with no `conflicts with` on stderr, the tool list names `subagent` and `web_fetch` exactly once each, `pi -p 'reply with ok'` still exits 0, and `find ~/.pi -newermt '-5 minutes'` returns nothing after the atomic run

      This check found a defect the pre-switch run could not, and it is the
      reason to keep it. Atomic exited 1 with four
      `Cannot find module '@earendil-works/pi-coding-agent'` errors, each naming
      a file under `~/.pi/agent/extensions/`. The neovim RPC path failed the
      same way, so atomic was unusable.

      Root cause, read from atomic's own `getAgentDirs()`: it carries `.pi` as
      `LEGACY_CONFIG_DIR_NAME`, and unless its agent-dir variable is set it
      returns `[~/.atomic/agent, ~/.pi/agent]`. Atomic therefore loaded pi's
      loose extensions, and the four that import the upstream pi package at
      runtime failed. The pre-switch run used a scratch `HOME` with no `~/.pi`,
      which is exactly why it passed. A scratch `HOME` cannot see a
      cross-harness collision; that is the class of defect this task exists for.

      Fixed by setting `ATOMIC_CODING_AGENT_DIR`, which makes `getAgentDirs()`
      return the primary alone. Verified by running atomic with the variable set:
      0 lines matching `.pi/agent/extensions`, 0 `conflicts with`, 0
      `Duplicate tool name`.

      Two consequences worth recording. First, that same legacy entry is how
      atomic read `~/.pi/agent/auth.json`, so atomic now reports
      `No API key found` until it is logged in once on its own; it writes
      credentials to `~/.atomic/agent`, and sharing one `auth.json` between two
      agents that both refresh OAuth tokens is the worse option. Second, the
      `find ~/.pi -newermt` criterion is now structural rather than empirical:
      with the directory pinned, atomic has no path that reads `~/.pi`.

      One pre-existing defect found and not fixed here, because it changes pi's
      behaviour and belongs to the pi module:
      `harnesses/pi/default.nix` sets `PI_SKIP_VERSION_CHECK = "$HOME/.pi"`, a
      path where a flag belongs. It matters beyond pi now, because atomic falls
      back to the `PI_` spelling of each of its own variables, so atomic was
      skipping its version check by inheriting that value. This module sets
      `ATOMIC_SKIP_VERSION_CHECK` explicitly so it no longer depends on it.
      Verified after the second switch, in a login shell started with
      `__HM_SESS_VARS_SOURCED` cleared: both variables are set, atomic reports 0
      `.pi/agent/extensions` errors, 0 `conflicts with`, 0
      `Duplicate tool name`, and `pi -p 'reply with ok'` still exits 0 and
      answers `ok`. Clearing that guard matters for the check: an already-running
      shell exported it before the switch, so a child login shell returns from
      `hm-session-vars.sh` early and reads none of the new variables. Any shell
      open across the switch needs a restart.

- [ ] 4.3 Check that atomic's permission gate is live by running one command the destructive allowlist denies, and confirming atomic refuses it rather than running it

      Blocked until atomic can reach a model. It has no credentials of its own
      yet, and the gate only runs on a real tool call. Unblocked by either giving
      atomic its own login, or copying pi's file once by hand:
      `cp ~/.pi/agent/auth.json ~/.atomic/agent/auth.json`. The copy keeps the
      two files independent, so neither agent's token refresh can overwrite the
      other's. This stays out of Nix either way, because credentials must not
      enter the store.
- [ ] 4.4 Confirm: the owner decides whether running two pi-lineage harnesses side by side is worth the shared `PI_*` environment surface, and whether the exclusion set is the set they want

      The phase 4 finding is the concrete form of this question. Atomic reads the
      `PI_` spelling of each of its own variables and, until this change, pi's
      whole agent directory. The directory is now pinned and the one variable
      atomic needed is set explicitly, so the remaining shared surface is any
      `PI_*` name the pi module sets that atomic also understands. Today that is
      one: `PI_SKIP_VERSION_CHECK`.
