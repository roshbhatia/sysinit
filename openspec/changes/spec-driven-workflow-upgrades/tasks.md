## 1. Slice 1 — adversarial-review-gating

- **SHAPE** graph

- [ ] 1.1 Add an owner approve/deny elicitation at the entry of `modules/home/programs/llm/skills/adversarial-review.nix` (before "Pick the execution path"); default to run, and on deny instruct recording `adversarial review: waived by owner`. `deps:` none
- [ ] 1.2 Soften `openspec/schemas/rosh-spec-driven/schema.yaml`: the tasks rule and design "Adversarial Review" section change from MUST-run to default-on, owner-gated; the deterministic `specreview` lint stays mandatory. `deps:` none
- [ ] 1.3 Record the divergence in `openspec/schemas/rosh-spec-driven/CHANGES.md`. `deps:` 1.2
- [ ] 1.4 Adversarial review (`adversarial-review` skill), owner-gated: critics attempt to break the gating slice against `specs/adversarial-review-gating/spec.md`; revise until no surviving objection or K=4 rounds (owner may waive for this small slice)
- [ ] 1.5 Verify: `openspec schema validate rosh-spec-driven` clean; `task openspec:sync` reports no drift; `nix flake check` green; `nh darwin build` green
- [ ] 1.6 Apply: `nh darwin switch`
- [ ] 1.7 Confirm: the regenerated `adversarial-review` skill contains the elicitation step; a small change can waive the loop and record the waiver

## 2. Slice 2 — task-phase-shapes

- **SHAPE** loop
- **STOP** `specreview` accepts the pass fixtures and rejects each fail fixture (shapeless, stop-less loop, dangling-dep graph)
- **MAX-ITERS** 3

- [ ] 2.1 Gather: add pass/fail fixture tasks.md snippets under a scratch dir (well-formed loop, well-formed graph, shapeless, stop-less, dangling-dep)
- [ ] 2.2 Act: extend `templates/tasks.md` and the `schema.yaml` tasks instruction to define `- **SHAPE** loop|graph`, `- **STOP**`, `- **MAX-ITERS**`, and `deps:` markers; record in `CHANGES.md`
- [ ] 2.3 Act: extend `modules/home/programs/llm/citation-tools/specreview.sh` with awk checks — each slice declares a shape; loop slices carry STOP + MAX-ITERS; graph `deps:` ids resolve to a subtask in the slice
- [ ] 2.4 Verify (loop): run the extended `specreview` against the fixtures; iterate 2.2-2.3 until STOP holds
- [ ] 2.5 Confirm no regression: run `specreview` against the archived `nix-idiom-cleanup` tasks.md and confirm shape checks are opt-in (do not retroactively fail it)
- [ ] 2.6 Adversarial review (`adversarial-review` skill), owner-gated: critics attempt to break the shape validation against `specs/task-phase-shapes/spec.md`; revise until no surviving objection or K=4 rounds
- [ ] 2.7 Verify: `nix flake check` green; `nh darwin build` green; `specreview` on this change's own tasks.md passes
- [ ] 2.8 Apply: `nh darwin switch`
- [ ] 2.9 Confirm: `specreview` accepts this file's `- **SHAPE**` markers; owner spot-checks the template/instruction text

## 3. Slice 3 — pplx-web-research

- **SHAPE** graph

- [ ] 3.1 Create `overlays/pplx.nix`: per-platform `fetchurl` of the v0.2.2 binary (darwin `sha256-6XZHj8/sUfNvWw8o1kd+oEIyMpQoTgawKi6bGzOcF3M=`, linux-arm `sha256-NfjfUxS2TupXONNuhTG4DgKeyvno3h1jF+XzsPZknqQ=`, linux-x86 `sha256-F+SP9yiuqaS5dptqCEQnq6lejhikPEvJxYR9BUw4tME=`), install to `$out/bin/pplx +x`, throw on unsupported platform (follows `overlays/localias.nix`). `deps:` none
- [ ] 3.2 Register the overlay in `overlays/default.nix` and add `pplx` to `flake.nix` `cacheAttrs`; add `pplx` to `home.packages`. `deps:` 3.1
- [ ] 3.3 Create `modules/home/programs/llm/skills/pplx-cli.nix` from the upstream SKILL.md (search/fetch commands, auth via `pplx auth`/`PERPLEXITY_API_KEY`, MM/DD/YYYY date flags, stderr error parsing); register in `skills/default.nix` with `allowed-tools = "Bash(pplx:*)"`. `deps:` none
- [ ] 3.4 Add the auth-conditional routing rule to the `pplx-cli` skill and a pointer from `openspec-workflow` / `citation-verification`: authed external research uses pplx, else WebSearch; never pplx for internal/private content. `deps:` 3.3
- [ ] 3.5 Adversarial review (`adversarial-review` skill), owner-gated: critics attempt to break the overlay + routing against `specs/pplx-web-research/spec.md` (unsupported-platform, unauthenticated fallback, internal-content leak); revise until no surviving objection or K=4 rounds
- [ ] 3.6 Verify: `nix flake check` green; `nh darwin build` green and `pplx` resolves on PATH; `pplx auth` reports unauthenticated and routing falls back to WebSearch
- [ ] 3.7 Apply: `nh darwin switch`
- [ ] 3.8 Confirm: `pplx --help` runs; owner may run `pplx auth login` to enable the authed path; unauthenticated research still uses WebSearch

## 4. Rollout

- [ ] 4.1 Verify: all three slices switched green; `openspec validate spec-driven-workflow-upgrades` passes
- [ ] 4.2 Apply: commit each slice as its own concern and `git push` to `main`
- [ ] 4.3 Confirm: `openspec list` shows the change ready to archive; owner spot-checks the three surfaces
