## 1. Slice 1: adversarial-review-gating

- **SHAPE** graph

- [x] 1.1 Add an owner approve/deny elicitation at the entry of `modules/home/programs/llm/skills/adversarial-review.nix` (before "Pick the execution path"); default to run, and on deny instruct recording `adversarial review: waived by owner`. `deps:` none
- [x] 1.2 Soften `openspec/schemas/rosh-spec-driven/schema.yaml`: the tasks rule and design "Adversarial Review" section change from MUST-run to default-on, owner-gated; the deterministic `specreview` lint stays mandatory. `deps:` none
- [x] 1.3 Record the divergence in `openspec/schemas/rosh-spec-driven/CHANGES.md`. `deps:` 1.2
- [x] 1.4 Adversarial review (owner approved): critic subagents were non-functional (empty tools / hallucinated reads), so fell back to the skill's path-4 self-critique. One real surviving objection: the new owner-gate preceded the recursion guard, so a spawned critic (CLAUDE_CODE_CHILD_SESSION) would hit the elicitation. Fixed by exempting child sessions first. No further objection survives.
- [x] 1.5 Verify: `openspec schema validate rosh-spec-driven` clean; `openspec validate` + `specreview` pass; `nix flake check` green; `nh darwin build` green
- [x] 1.6 Apply: `nh darwin switch`
- [x] 1.7 Confirm: the regenerated `adversarial-review` skill contains the elicitation step; a small change can waive the loop and record the waiver

## 2. Slice 2: task-phase-shapes

- **SHAPE** loop
- **STOP** `specreview` accepts the pass fixtures and rejects each fail fixture (shapeless, stop-less loop, dangling-dep graph)
- **MAX-ITERS** 3

- [x] 2.1 Gather: add pass/fail fixture tasks.md snippets under a scratch dir (well-formed loop, well-formed graph, shapeless, stop-less, dangling-dep)
- [x] 2.2 Act: extend `templates/tasks.md` and the `schema.yaml` tasks instruction to define `- **SHAPE** loop|graph`, `- **STOP**`, `- **MAX-ITERS**`, and `deps:` markers; record in `CHANGES.md`
- [x] 2.3 Act: extend `modules/home/programs/llm/citation-tools/specreview.sh` with awk checks: each slice declares a shape; loop slices carry STOP + MAX-ITERS; graph `deps:` ids resolve to a subtask in the slice
- [x] 2.4 Verify (loop): run the extended `specreview` against the fixtures; iterate 2.2-2.3 until STOP holds
- [x] 2.5 Confirm no regression: run `specreview` against the archived `nix-idiom-cleanup` tasks.md and confirm shape checks are opt-in (do not retroactively fail it)
- [x] 2.6 Adversarial review (self-critique; subagents broken): found the em-dash violation message was swallowed by the redirect (failure fired but reason hidden). Routed both STE violation kinds through stdout so reasons show. No further objection.
- [x] 2.7 Verify: `nix flake check` green; `nh darwin build` green; `specreview` on this change's own tasks.md passes
- [x] 2.8 Apply: `nh darwin switch`
- [x] 2.9 Confirm: `specreview` accepts this file's `- **SHAPE**` markers; owner spot-checks the template/instruction text

## 3. Slice 3: pplx-web-research

- **SHAPE** graph

- [x] 3.1 Create `overlays/pplx.nix`: per-platform `fetchurl` of the v0.2.2 binary (darwin `sha256-6XZHj8/sUfNvWw8o1kd+oEIyMpQoTgawKi6bGzOcF3M=`, linux-arm `sha256-NfjfUxS2TupXONNuhTG4DgKeyvno3h1jF+XzsPZknqQ=`, linux-x86 `sha256-F+SP9yiuqaS5dptqCEQnq6lejhikPEvJxYR9BUw4tME=`), install to `$out/bin/pplx +x`, throw on unsupported platform (follows `overlays/localias.nix`). `deps:` none
- [x] 3.2 Register the overlay in `overlays/default.nix` and add `pplx` to `flake.nix` `cacheAttrs`; add `pplx` to `home.packages`. `deps:` 3.1
- [x] 3.3 Create `modules/home/programs/llm/skills/pplx-cli.nix` from the upstream SKILL.md (search/fetch commands, auth via `pplx auth`/`PERPLEXITY_API_KEY`, MM/DD/YYYY date flags, stderr error parsing); register in `skills/default.nix` with `allowed-tools = "Bash(pplx:*)"`. `deps:` none
- [x] 3.4 Add the auth-conditional routing rule to the `pplx-cli` skill and a pointer from `openspec-workflow` / `citation-verification`: authed external research uses pplx, else WebSearch; never pplx for internal/private content. `deps:` 3.3
- [x] 3.5 Adversarial review (self-critique; subagents broken): found two bugs at live-confirm: `pplx auth status` is not a real subcommand (only `login`), and a `''${...}` antiquotation in the skill string broke the Nix build. Fixed the auth check (env var or credentials file) and escaped the string. No further objection.
- [x] 3.6 Verify: `nix flake check` green; `nh darwin build` green and `pplx` resolves on PATH; `pplx auth` reports unauthenticated and routing falls back to WebSearch
- [x] 3.7 Apply: `nh darwin switch`
- [x] 3.8 Confirm: `pplx --help` runs; owner may run `pplx auth login` to enable the authed path; unauthenticated research still uses WebSearch

## 4. Slice 4: artifact-writing-standards

- **SHAPE** graph

- [x] 4.1 Add a shared "rosh-spec-driven rule" to the `schema.yaml` artifact instructions: write every artifact in Simplified Technical English per the `~/.claude/CLAUDE.md` Communication section; record in `CHANGES.md`. `deps:` none
- [x] 4.2 Extend `modules/home/programs/llm/citation-tools/specreview.sh`: fail on an em-dash in any artifact; fail on a bulleted bold lead outside the allowed keyword set (`WHEN`/`THEN`/`AND`/`POLARITY`/`SHAPE`/`STOP`/`MAX-ITERS`/`BREAKING`). `deps:` none
- [x] 4.3 Verify: run the extended `specreview` against a conforming fixture and against em-dash and bold-lead fixtures; confirm this change's own artifacts pass. `deps:` 4.2
- [x] 4.4 Adversarial review (self-critique; subagents broken): found the STE rule was recorded in `CHANGES.md` but never added to `schema.yaml`. Added it as proposal rule 6, stated to apply to every artifact. No further objection.
- [x] 4.5 Verify: `nix flake check` green; `nh darwin build` green; `specreview` on this change passes
- [x] 4.6 Apply: `nh darwin switch`
- [x] 4.7 Confirm: `specreview` rejects an em-dash fixture and accepts this change's artifacts

## 5. Rollout

- [x] 5.1 Verify: all four slices switched green; `openspec validate spec-driven-workflow-upgrades` passes
- [x] 5.2 Apply: commit each slice as its own concern and `git push` to `main`
- [x] 5.3 Confirm: `openspec list` shows the change ready to archive; owner spot-checks the four surfaces
