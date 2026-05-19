## Context

The three existing `write-{commit,pr-body,issue}-roshan` skills live at `modules/home/programs/llm/skills/write-{commit,pr-body,issue}-roshan.nix` and are imported into the skill registry at `modules/home/programs/llm/skills/default.nix`. Each `.nix` file returns a multi-line string that becomes the body of the rendered `~/.claude/skills/<name>/SKILL.md`. The registry layout and per-skill file structure is governed by the existing `agent-skill-library` spec at `openspec/specs/agent-skill-library/spec.md`.

The current commit and PR-body skill bodies were inferred from a hand-picked ~5-PR sample drawn from this sysinit repo itself. The corpus collected for this change — 295 PRs, 504 commits, and per-PR comments in `github.com/pinginc` before 2024-06-01 — represents the same author's pre-LLM-coupled writing and contradicts the v0.1 rules along several axes. The corpus lives at `.sysinit/laurel-corpus/` and is gitignored via the user-level `~/.config/git/ignore`. The third (deleted) skill `write-issue-roshan` gets little real-world use; rather than carry forward a thinly-supported skill, it is removed outright.

The `opinionated-code-comments` skill is new and does not have a dedicated corpus. Its content derives from two existing sources: the "default to writing no comments" stance already in `CLAUDE.md` (under `# Doing tasks`), and the terse / lowercase-preferred voice observed in the corpus prose. The skill exists because inline-comment style is a recurring drift surface for LLM-generated code and is not adequately reinforced by a single CLAUDE.md line.

Reused patterns:
- The four-file per-skill layout follows the existing convention in `modules/home/programs/llm/skills/`.
- The registry-entry shape `{ description = "..."; content = import ./<name>.nix; }` is reused unchanged from `agent-skill-library`'s "Skill registry is the single source of truth" requirement.
- The `## Negative scenarios` block style at the bottom of each existing SKILL.md is reused as the format for documenting anti-patterns in the new skills.

No new pattern is introduced; this change replaces content within an existing capability surface.

## Goals / Non-Goals

Goals:
- The two rewritten skills accurately reflect the corpus voice as it existed before 2024-06-01, not the v0.1 inferred rules.
- Each skill is self-contained — it reads as a generic opinionated style guide with no proper-noun anchor.
- The three skills land as a coherent set: a shared voice across commits, PRs, and source-code comments.
- The PR-body skill MUST delegate body shape to the repo PR template when one exists and MUST NOT mutate the template's checklist (no appended items).
- Anti-patterns observed only in LLM-generated output (bolded list rows, em-dash elaboration, multi-sentence bullets, "Generated with..." trailers) are explicitly listed so the agent rejects them at draft time.
- Repo-override sweeps (CONTRIBUTING.md, PR template detection, DCO sign-off) survive intact.

Non-goals:
- Retroactively re-applying the new voice to existing PRs, commits, or issues.
- Capturing the voice of writing produced AFTER 2024-06-01.
- Hardcoding Laurel-era ticket-project codes (OWL, TO, TLS, ...) as a known vocabulary. They appear in historical examples but are not required vocabulary for future work.
- Refactoring the registry or the per-agent install paths handled by `agent-skill-library`.
- Authoring a separate corpus for source-code comments. The `opinionated-code-comments` skill cross-references the existing CLAUDE.md stance and the prose voice from the corpus, not a separate ground-truth sample.
- Preserving the deleted `write-issue-roshan` skill or any of its rules. The skill is removed outright.

## Decisions

### One new capability `opinionated-writing-skills` covering all three skills, not three separate capabilities

The three skills share one author, one set of cross-cutting anti-patterns (no bolded lists, no emojis, no em-dashes, no checklist-mutation, no auto-submit), and a unified voice that bridges prose (commits, PR bodies) and code prose (source comments). Splitting into three capabilities would force the cross-cutting rules to be duplicated three times or extracted into a shared parent, both of which are heavier than a single capability with three requirements. The three-in-one shape also makes the corresponding tasks.md a single coherent unit rather than three interleaved deltas.

Alternative considered: three separate capabilities, one per skill. Rejected because the cross-cutting rules dominate the per-skill differences and would create duplication. Also rejected because the three skills must land together for the `default.nix` import to compile — separating them at the spec level while uniting them at the implementation level is incoherent.

### Skill slug pattern `opinionated-<artifact>` instead of `<artifact>-style` or `house-style-<artifact>`

`opinionated-` reads as a prefix-as-mood marker rather than a person or place. The user picked it during the explore phase. The compact form (`opinionated-commit`, not `opinionated-commit-message`) drops a redundant `-message`/`-body` suffix since the artifact name already implies it.

Alternative considered: `style-<artifact>`. Rejected as lower-signal — "opinionated" foregrounds that the skill makes claims, while "style" suggests neutrality.

Alternative considered: `<artifact>-roshan` (current naming with renames preserving the personal anchor). Rejected per user direction — fully de-personalize.

### Delegate PR body shape to the repo PR template entirely, with `## Summary` + optional `## Validating Changes` as fallback

The corpus shows pinginc PRs followed a mandatory template with `## Summary`, `## Checklist`, and an optional `## Validating Changes (ad-hoc, if logic is not covered by automated tests)`. The current v0.1 skill prescribes `## Summary` + `## Risks`/`## Test plan`, which is sysinit-specific (no template) and does not generalize. The new rule is: if a PR template exists, fill it verbatim and never append items to its checklist; if no template exists, fall back to the corpus-observed fallback.

Alternative considered: keep `## Risks` / `## Test plan` as the no-template fallback. Rejected because the corpus does not use those sections; they were invented by the v0.1 skill for repos without templates.

Alternative considered: drop the fallback entirely and require a template. Rejected because the user contributes to repos without PR templates (sysinit itself, some upstream OSS) and the skill needs an opinion in that case.

### Explicit anti-pattern list at the bottom of each skill rather than embedded prohibitions

The corpus is silent on what NOT to do; only the contrast with LLM output reveals the anti-patterns. Listing them as a `## What to avoid` block at the end of each skill makes them easy to scan and easy to extend when new anti-patterns are noticed. Embedding the same prohibition inline next to each rule would scatter the same prohibition across the document.

Alternative considered: inline prohibitions per rule. Rejected because the same prohibitions (no emojis, no bolded lists) recur in every skill and inline restatement is noisier than a single end-block.

### Skill content stays plain prose; no bolded list rows used in the skill BODY itself

The skills teach the agent not to write `- **Foo**: bar` list rows in artifacts. Using that exact pattern inside the skill body would be hypocritical and would also model the wrong pattern back to the agent at read time. The skills are written in plain bullets and short paragraphs with backticked identifiers as the only inline emphasis.

Alternative considered: use bolded list rows for skill rules (the conventional Markdown style). Rejected because the skill content is itself a writing-style demonstration; modeling the anti-pattern undermines the lesson.

## Rollout & Gating

The change lands in two slices, each gated by `nix flake check` and `nh os build`:

Slice 1 — content authoring (reversible, contained to `openspec/changes/`):
1. Author the four skill bodies under `openspec/changes/rewrite-opinionated-writing-skills/` (in design and specs, not yet in `modules/`).
2. User reviews the four bodies in the OpenSpec change directory before any nix source file is touched.

Gate before slice 2: user confirms the four bodies are correct.

Slice 2 — nix wiring + rename (single atomic switch, since the import map must be consistent):
1. Add four new `modules/home/programs/llm/skills/opinionated-*.nix` files containing the bodies.
2. Update `modules/home/programs/llm/skills/default.nix` to register the four new names and unregister the three old ones in one edit.
3. Delete the three `write-*-roshan.nix` files.
4. Update `CLAUDE.md` and any `AGENTS.md` references in the same edit pass.
5. Run `nix flake check`.
6. Run `nh os build` and review the symlink diff under `~/.claude/skills/`.
7. User runs `nh os switch` themselves — this step is never auto-run.

Kill switch: the change is fully reversible by reverting the slice 2 commits. The renamed slugs are not persisted anywhere outside the nix source tree and `~/.claude/skills/` symlinks (regenerated each switch).

Capability gate: none beyond the standard `nh os build` → `nh os switch` sequence.

## Risks / Trade-offs

- [Skill slug rename breaks slash-command muscle memory] → call out the rename in the change archive and in the commit message subject so the user notices when they next type the old name.
- [The three-in-one capability bundles independent voice rewrites] → mitigated by the slice-1 gate (review all three bodies before any nix edit); the user can defer or scope-cut any during review without re-cutting the change. Maps to a human-verification checkpoint in `tasks.md`.
- [`opinionated-code-comments` has no dedicated corpus] → flag this in the skill body itself with a "derived from CLAUDE.md stance plus corpus prose voice" provenance note. The skill is the highest-drift surface and the rules are kept narrow to reduce false positives.
- [De-personalizing the skills loses the historical anchor that "this voice comes from a specific person's pre-2024 writing"] → mitigated by leaving the anchor in the `description` field metadata (e.g., "Derived from a pre-2024 personal-OSS corpus"). Skill body stays de-personalized; description carries the provenance.
- [Anti-patterns list grows over time and could drift from the actual corpus] → mitigated by keeping the corpus at `.sysinit/laurel-corpus/` available for re-analysis, and by limiting the anti-pattern list to patterns directly observed in LLM output vs. absent from the corpus, not to speculative prohibitions.
- [LaurelLinear ticket-ID pattern documented but flagged as historical] → the skill explicitly does NOT require ticket IDs for current work; risk is the agent over-applies the pattern. Mitigated by labeling the section "historical pattern" and pairing with a counter-example of acceptable no-ticket subjects.

## Migration Plan

Pre-edit verification:
- Confirm the four skill bodies in the OpenSpec change directory satisfy slice 1's gate (user approval).

Atomic edit pass (slice 2):
- Stage all four `opinionated-*.nix` files, the `default.nix` edit, the three `write-*-roshan.nix` deletions, and the `CLAUDE.md`/`AGENTS.md` updates as a single commit candidate.

Verification steps before mutating the system:
- `nix flake check` MUST pass.
- `nh os build` MUST complete without error.
- User inspects the `nh os build` symlink diff for `~/.claude/skills/` and confirms the new names appear and the old names are removed.

Apply step (user-initiated):
- User runs `nh os switch`. This is an impactful action and is NEVER auto-run by the agent.

Post-apply confirmation:
- User invokes one of the new slash commands (e.g., types the new skill name) to confirm the skill is registered and resolvable.
- If the new skills are not present, revert the slice 2 commits and re-run `nh os switch` to restore the old skills.

Rollback:
- `git revert` the slice 2 commits.
- `nh os switch` to re-link the old skill names.

## Open Questions

- Whether the three new skills should be added to the `agent-skill-library` spec's "Required global skills" list. The existing spec lists `shell-scripting`, `openspec-*`, `find-skills`, `seshy`, `cocoindex-query` as required. Adding writing skills shifts the required set from infrastructure-only to "infrastructure + house style". Resolve during the specs phase or defer to a follow-up change.
- Whether the historical ticket-ID pattern should be illustrated with the actual `OWL-XXXX` / `TO-XXX` codes from the corpus or with `PROJECT-NNN` as a generic placeholder. Concrete codes are more grounded but also embed pinginc-specific vocabulary. Resolve in the spec.
- Whether `opinionated-code-comments` should fire automatically on every Edit/Write of a source file or only on demand (`/opinionated-code-comments` invocation). On-demand keeps the skill narrow; automatic invocation risks too-eager comment removal. Resolve in the spec.
