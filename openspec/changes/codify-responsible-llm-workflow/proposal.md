## Why

The generated global instructions define tool use and safety, but they do not
state who owns model-assisted work. The user selected Oxide RFD 576 as the
design input for that responsibility contract. The captured source states that
"LLMs are but a tool" [rfd576-responsibility].

## What Changes

- Add a compact responsibility section to every generated global context.
- Separate deterministic checks, model critique, peer review, and owner decisions.
- Make model critique optional without waiver language.
- Require complete-diff review before handoff and targeted edits during review.
- Strengthen source selection and authored-voice rules in their owning skills.

The change extends `modules/home/programs/llm/lib/instructions.nix`, the existing
single source for global context. It also extends the current skill-owned policy
pattern instead of placing domain rules in every `AGENTS.md`.

### Non-goals

- Requiring or prohibiting LLM use.
- Replacing human peer review with model review.
- Adding model attribution to generated artifacts.
- Changing harness-specific personality settings.
- Changing the deterministic `specutil check` requirement.

## Behavior

Must do:
- Every generated global context states that the user owns decisions and artifacts, decided by the context-render checks.
- A model critic result cannot represent owner or peer approval, decided by schema and skill source inspection.
- Skipping model critique uses neutral `not run` language, decided by inspecting the schema, template, skill, and canonical specification.
- Handoff requires complete-diff review and relevant checks, decided by the generated responsibility section.
- Review feedback produces targeted edits instead of wholesale regeneration, decided by the workflow skill text.

Must still hold:
- `specutil check` remains mandatory, decided by the schema and adversarial-review skill.
- Human gates remain limited to judgment and impactful actions, decided by the schema task instructions.
- Harness context remains generated from one source, decided by `nix flake check`.

Human-owned decision:
- The owner approves the responsibility policy and any live activation.

## Impact

Modified code:
- `modules/home/programs/llm/lib/instructions.nix`
- `modules/home/programs/llm/skills/openspec-workflow/SKILL.md`
- `modules/home/programs/llm/skills/adversarial-review/SKILL.md`
- `modules/home/programs/llm/skills/citation-verification/SKILL.md`
- `modules/home/programs/llm/skills/writing-tone/SKILL.md`
- `openspec/specs/agent-context-files/spec.md`
- `openspec/specs/adversarial-review-gating/spec.md`
- `overlays/openspec/rosh-spec-driven/schema.yaml`
- `overlays/openspec/rosh-spec-driven/templates/`
- `openspec/config.yaml`

Dependencies:
- `package-global-openspec-schema` establishes the schema source location.
- `close-harness-instruction-gaps` establishes global context coverage.

Impactful and irreversible actions:
- `git push` publishes the policy.

Gating signal: `nix flake check`, then an explicit Darwin build and rendered-context inspection.
