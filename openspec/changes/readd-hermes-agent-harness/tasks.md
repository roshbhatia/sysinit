## 1. Package

- **SHAPE** graph
- **MERGE** 1.4

- [x] 1.1 Add the `hermes-agent` flake input with its own nixpkgs pinned to a revision, following the `hunk` input's form in `flake.nix`; read upstream's `flake.lock` for the revision they test against `writes:` flake.nix, flake.lock `deps:` none

      Pinned to `0954f7ee2f6bb3dc7d4e3d0d8bcb8fd4bde4cfc5`, read from upstream's
      own `flake.lock`. This settles the first open question in `design.md`.
- [x] 1.2 Write `overlays/hermes-agent.nix` over `packages.${system}.minimal` with `extraDependencyGroups = [ "anthropic" ]`, re-wrapping `hermes`, `hermes-agent`, and `hermes-acp` with a prefixed subagent PATH, and register it in `overlays/default.nix` `writes:` overlays/hermes-agent.nix, overlays/default.nix `deps:` 1.1

      Upstream's own `nix/hermes-agent.nix` wraps the same three entrypoints
      with `--suffix PATH`, so this overlay's `--prefix` lands ahead of theirs
      rather than fighting it.
- [x] 1.3 Record the closure-size delta and wall-clock build time for the darwin configuration, so the cost is a number the owner can price rather than an impression `writes:` none `deps:` 1.2

      Measured on lv426, cold, 2026-08-10. `nix build --dry-run` reports 682
      derivations to build and 504 paths to fetch (116.5 MiB download,
      330.3 MiB unpacked). Wall clock for `nix build` of the overlay's
      `hermes-agent`: 4m37s. The built closure is 445 paths and 3.7 GiB. Against
      the running `/run/current-system`, 329 of those paths are new and add
      2.38 GiB of nar. This is the number task 1.6 asks the owner to price.
- [x] 1.4 Build both configurations, then grep `nix-store --query --requisites` over each result for `torch`, `faster-whisper`, `ctranslate2`, and `onnxruntime`; a hit means `minimal` is not the output that got consumed `writes:` none `deps:` 1.2, 1.3

      Zero matches over the 445-path closure of
      `minimal` + `extraDependencyGroups = [ "anthropic" ]`. Run as a negative
      control against the `default` output's derivation closure, the same grep
      finds `torch-2.12.0`, `pytorch`, `faster-whisper-1.2.1`,
      `ctranslate2-4.8.1`, and `onnxruntime-1.27.1`, so the grep detects the
      stack rather than passing vacuously. That control answers the first risk
      named in `review.md`.

      Deviation on the linux half. lv426 has no linux builder: `builders` reads
      an absent `/etc/nix/machines` and `extra-platforms` is `x86_64-darwin`
      only, so `nix build` of the arrakis toplevel cannot realise an uncached
      linux derivation and hermes is uncached everywhere. The criterion was
      decided instead over the derivation closure of
      `nixosConfigurations.arrakis.pkgs.hermes-agent`, whose `system` field is
      `x86_64-linux`: 7406 paths, zero matches for the four names. That decides
      closure membership without realising the paths. Running the criterion as
      written stays open until someone runs it on arrakis.
- [x] 1.5 Adversarial review (`adversarial-review` skill): critics attempt to break the package phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state (see the skill for the scaled round cap)

      Terminal state: `not run`. The owner directed on 2026-08-10 that the apply
      proceed on deterministic lint alone. `review.md` records the three risks
      that stay unexamined.
- [x] 1.6 Confirm: the owner accepts the measured build time and closure delta from 1.3, given that upstream classes the Nix path as best-effort and nothing substitutes this derivation

      Accepted 2026-08-10. The owner was shown the 4m37s build, the 3.7 GiB
      closure, and the 2.38 GiB delta, then directed the apply.

## 2. Harness module

- **SHAPE** graph
- **MERGE** 2.5

- [x] 2.1 Add the `hermes` entry to `harnesses/registry.nix` with `package = "hermes-agent"`, `context`, `skillLoader`, `ownIcon`, `notify`, `bridge`, and `neovimAdapter` filled in per the proposal `writes:` modules/home/programs/llm/harnesses/registry.nix `deps:` none

      `context = "~/.hermes/SOUL.md"`, not `config.yaml`. SOUL.md is the file
      hermes injects into the system prompt, so it is the one a reader should
      open. `design.md` records the reasoning.
- [x] 2.2 Write `harnesses/hermes.nix` following `harnesses/goose.nix`, owning `~/.hermes/config.yaml` through `sysinit.llm.managedFiles` with `format = "yaml"`; the deleted `yq` activation script MUST NOT come back `writes:` modules/home/programs/llm/harnesses/hermes.nix `deps:` 2.1

      Declares `mcp_servers`, `skills.external_dirs`, and
      `telemetry.shared_metrics.enabled`. `enforce` covers the last two;
      `mcp_servers` merges and `retire` deletes the suppressed names, the same
      split `goose.nix` uses. No activation script.
- [x] 2.3 Restore `formatForHermes` in `lib/mcp.nix` beside the nine existing formatters, emitting `command`/`args` for stdio servers and `url` for http servers `writes:` modules/home/programs/llm/lib/mcp.nix `deps:` none

      Restored byte-for-byte from `3dd95d8e8`, with `with lib` rewritten to
      `lib.optionalAttrs` to match the file's current form. The pinned
      `cli-config.yaml.example` documents the same `mcp_servers` shape the
      deleted formatter emitted, so no key needed changing.
- [x] 2.4 Declare `skills.external_dirs` in the managed config so hermes reads `~/.claude/skills` in place, and do NOT restore the deleted renderer; its `<category>/<name>/SKILL.md` layout and `metadata.hermes.category` key are not what the pinned version reads `writes:` modules/home/programs/llm/harnesses/hermes.nix `deps:` 2.2

      Proven before the switch, not after. With `HERMES_HOME` pointed at a
      scratch directory whose `config.yaml` sets `external_dirs` to
      `~/.claude/skills`, `hermes skills list` names 79 skills, which is every
      `SKILL.md` directory on disk. The control run with `external_dirs` unset
      names none. This replaces the renderer task the proposal originally
      carried; `design.md` records the two rejected alternatives.
- [x] 2.5 Build both configurations, then parse the rendered `~/.hermes/config.yaml` with `yq` and compare its `mcp_servers` keys against the catalog minus `suppressedServers` `writes:` none `deps:` 2.2, 2.3, 2.4

      The darwin configuration builds; the linux one evaluates under
      `nix flake check` but cannot be realised here, for the reason recorded
      under 1.4. The rendered
      `managed-hermes-new.json` carries `mcp_servers` keys `ast-grep`,
      `basic-memory`, and `playwright`, which is the whole catalog: this host
      suppresses nothing, so `retire` is empty and the comparison is against the
      catalog itself. The suppression path is therefore declared but unexercised
      on lv426.
- [x] 2.6 Adversarial review (`adversarial-review` skill): critics attempt to break the module phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      Terminal state: `not run`, per the owner's direction recorded in
      `review.md`.

## 3. Editor route

- **SHAPE** graph
- **MERGE** 3.3

- [x] 3.1 Write `harness/adapters/hermes.lua` following `adapters/goose.lua`, and add `hermes` to the `ORDER` list in `harness/registry.lua` `writes:` modules/home/programs/neovim/config/lua/harness/adapters/hermes.lua, modules/home/programs/neovim/config/lua/harness/registry.lua `deps:` none

      `cmd = "hermes"`, `args = { "chat" }`, and 13 options. Every flag in the
      schema was read off `hermes chat --help` from the built store path rather
      than from the top-level `hermes --help`, because the two parsers accept
      different sets.
- [x] 3.2 Add the evaluation-time assertion in `runtime/default.nix` that every registry `neovimAdapter` value names an existing file under the neovim adapters directory `writes:` modules/home/programs/llm/runtime/default.nix `deps:` none

      Prepended to the `agent-notify-icons` command string beside
      `assertBridgesExist`, so it is forced by the same derivation both
      configurations already build.
- [x] 3.3 Build both configurations, run the headless neovim check that `get_by_name("hermes")` returns a table, then inject `neovimAdapter = "nope"` and require the darwin build to exit non-zero with the assertion's own message `writes:` none `deps:` 3.1, 3.2

      `nix flake check` passes, which is where `nixosConfigurations.arrakis`
      evaluates, and the darwin configuration builds to
      `darwin-system-26.11.15abb8c`; its closure carries hermes and matches none
      of the four speech-stack names. Headless neovim returns the adapter table
      and loads 12 adapters, up from 11. With `neovimAdapter = "nope"` injected,
      evaluation fails with the assertion's own message; the registry was
      restored from a copy rather than by `git checkout`, because the file
      carries uncommitted work.
- [x] 3.4 Adversarial review (`adversarial-review` skill): critics attempt to break the editor phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      Terminal state: `not run`, per the owner's direction recorded in
      `review.md`.

## 4. Rollout

- [x] 4.1 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout, gated on `nix flake check` and `nh darwin build` exiting 0

      Pushed as `7650733b4`. `nh darwin switch . --update` from
      `sysinit.laurel` exited 0. The live closure went 1251 -> 1582 paths and
      16.7 -> 19.0 GiB, which is 2.3 GiB, matching the 2.38 GiB predicted in 1.3.
      Neither the brew-trust abort nor the App Management exit-1 appeared.
- [ ] 4.2 Run the post-switch checks: `hermes --version`, `hermes-acp --help`, the credential grep over the built store path, and a hermes session from `env -i PATH=/usr/bin:/bin` resolving the six subagent binaries

      Three of the four already pass against the built store path, before any
      switch. `hermes --version` reports `Hermes Agent v0.20.0 (2026.8.3)`,
      matching the pinned `pyproject.toml`. `hermes-acp --help` exits 0 and
      prints the ACP stdio usage. The credential grep over the wrapper's tree
      returns nothing. The wrapper prefixes six store bin directories, and
      `claude`, `codex-acp`, `opencode`, `copilot`, `gh`, and `gemini` all
      resolve from them with only `/usr/bin:/bin` behind. What is left for after
      the switch is `command -v hermes` resolving from the profile.

      After the switch, all four pass on the live machine. `command -v hermes`
      is `/etc/profiles/per-user/roshan/bin/hermes` and reports
      `Hermes Agent v0.20.0 (2026.8.3)`. All six subagents resolve off the
      profile wrapper's own prefixed dirs. `~/.hermes/SOUL.md` is a store
      symlink. `hermes skills list` names 79 local skills, which is every
      `SKILL.md` directory under `~/.claude/skills`, plus 87 hermes builtins.
- [ ] 4.3 Confirm: the owner runs `hermes` once and decides whether the keys in `~/.hermes/config.yaml` are the ones they meant this repository to declare

      One finding for the owner to rule on. `~/.hermes/config.yaml` survived the
      2026-07-01 removal, so the file the merge found was 582 lines of the
      owner's own settings. `skills.external_dirs` and
      `telemetry.shared_metrics` are enforced and now read as declared.
      `mcp_servers` is not enforced, so the on-disk map won: it lists
      `agentgateway`, `cocoindex`, and `incident-io`, while `sysinit.laurel`
      declares only `agentgateway`. `cocoindex` and `incident-io` are servers
      this host stopped declaring before the removal, and neither `enforce` nor
      `retire` reaches them, because `retire` covers `suppressedServers` only.

      This is the established behaviour, not a hermes-specific fault:
      `~/.config/goose/config.yaml` carries the same two names for the same
      reason. The owner's call is whether to add `mcp_servers` to `enforce`,
      which makes the catalog authoritative at the cost of wiping whatever
      `hermes mcp add` writes, or to delete the two keys by hand once.

      Resolved 2026-08-11 by adding `["mcp_servers"]` to `enforce` in
      `harnesses/hermes.nix`, and removing the `retire` block it makes dead.
      `enforce` replaces the whole subtree with the Nix value
      (`setpath($p; $n | getpath($p))` in `lib/managed-file.nix`), so the catalog
      is now authoritative for every key rather than only for the suppressed
      ones. Deleting the two keys by hand was rejected: it fixes the two names
      that drifted and leaves the mechanism that let them drift in place.

      The trade is recorded in the module. A server added by `hermes mcp add` is
      dropped on the next switch, which follows the standing rule that
      hand-managed configuration gives way to the Nix source that generates it.

      Still the owner's: run `hermes` once and confirm the resulting key set is
      what this repository should declare. Nothing here can settle that.

      Separate from this change: `harnesses/goose.nix` has the same
      `retire`-covers-suppressed-only shape and the same two stale keys on disk.
      Left alone deliberately, so goose moves in its own commit rather than
      riding along in this one.
