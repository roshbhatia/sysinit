## 1. Task-graph rules in the schema

- **SHAPE** graph
- **MERGE** 1.7

- [x] 1.1 Rewrite the tasks instruction in `modules/home/programs/llm/openspec-schema/schema.yaml`: replace the "order by dependency" sentence with the fake-edge test, key the fan-out prohibition on overlapping write sets rather than on shared output, define the two new graph markers, state that a task's prose MUST NOT repeat a marker label and MUST NOT open with a kind verb because the extractor takes the first match on the line and strips a leading kind word, and delete the note that bolding TERMINAL fails the lint `deps:` none `writes:` modules/home/programs/llm/openspec-schema/schema.yaml
- [x] 1.2 Carry the two new markers into `modules/home/programs/llm/openspec-schema/templates/tasks.md`, give the merge marker a concrete placeholder id rather than an HTML comment because a comment satisfies the presence check while naming no task, and promote the terminal marker to its bolded form so the allowlist entry corresponds to something the template emits `deps:` 1.1 `writes:` modules/home/programs/llm/openspec-schema/templates/tasks.md
- [x] 1.3 Write `modules/home/programs/llm/openspec-schema/specutil.yaml` with an extraction block for the two new markers and a rubric block stating `preset: spec-driven` plus the three appended rules, using the marker names 1.1 defines, wording every comment so it does not itself contain a string the Behavior criteria grep for, and symlink `openspec/specutil.yaml` to it `deps:` 1.1 `writes:` modules/home/programs/llm/openspec-schema/specutil.yaml openspec/specutil.yaml
- [x] 1.4 Resolve the adversarial-review section contradiction inside the fork, which the rubric override alone does not reach: `templates/design.md` emits the section labelled REQUIRED, and both skill files tell the author to satisfy it in wording that carries no heading marker `deps:` 1.1 `writes:` modules/home/programs/llm/openspec-schema/templates/design.md modules/home/programs/llm/skills/adversarial-review/SKILL.md modules/home/programs/llm/skills/adversarial-review/references/adversarial-review-methodology.md
- [x] 1.5 Run the rubric against input this change did not author: copy every change under `openspec/changes/archive/` into a scratch active tree, run `specutil check` with and without the local rubric, and record which findings the added rules produce and which are unchanged `deps:` 1.3 `writes:` none
- [x] 1.6 Record the schema change in `modules/home/programs/llm/openspec-schema/CHANGES.md`, following the existing dated-entry style `deps:` 1.2 1.3 1.4 `writes:` modules/home/programs/llm/openspec-schema/CHANGES.md
- [x] 1.7 Merge: run `specutil check`, `spec-preflight all graph-shaped-task-execution`, `specutil render graph-shaped-task-execution --as tickets`, and `nix eval --raw .#darwinConfigurations.lv426.system.drvPath`, then reconcile any marker name the schema, the template, and the rubric spell differently `deps:` 1.2 1.4 1.5 1.6 `writes:` modules/home/programs/llm/openspec-schema/schema.yaml modules/home/programs/llm/openspec-schema/templates/tasks.md modules/home/programs/llm/openspec-schema/specutil.yaml
- [x] 1.8 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 1.7 `writes:` openspec/changes/graph-shaped-task-execution/review.md

## 2. Owner route into a seshy session

- **SHAPE** graph
- **MERGE** 2.2

- [ ] 2.1 Make the wezterm workspace switcher spawn a seshy target through `s`. `s` is a zsh function in `modules/home/programs/zsh/integrations/seshy-wezterm.zsh`, not an executable, so the switcher MUST delegate to an interactive zsh rather than call it directly, and MUST fall back to a plain workspace when that shell or its `command -v` guards fail `deps:` none `writes:` modules/home/programs/wezterm/lua/sysinit/pkg/ui/switcher.lua
- [ ] 2.2 Merge: run `hack/lint.sh --all` and `nix build .#darwinConfigurations.lv426.system`, then decide the positive path by name: `zmx kill` a scratch session, open that workspace from the switcher, and confirm `zmx ls` reports the name where it did not before. Confirm the negative path separately by breaking one guard `deps:` 2.1 `writes:` modules/home/programs/wezterm/lua/sysinit/pkg/ui/switcher.lua
- [ ] 2.3 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 2.2 `writes:` openspec/changes/graph-shaped-task-execution/review.md

## 3. Rollout

- [ ] 3.1 Apply: `nh darwin switch`, gated on `hack/lint.sh --all`, `nix flake check`, `nix build .#darwinConfigurations.lv426.system`, and `nix eval --raw .#nixosConfigurations.arrakis.config.system.build.toplevel.drvPath` exiting 0
- [ ] 3.2 Confirm: the owner reads the rewritten fan-out paragraph and the fake-edge test in the rendered schema, decides whether the write-set rule declines the cases they wanted declined, and decides whether the tasks instruction is now too long to be followed
- [ ] 3.3 Apply: `openspec archive graph-shaped-task-execution`, gated on `specutil check` exiting 0
