## Why

Four of the eleven configured harnesses receive nothing from
`modules/home/programs/llm/lib/instructions.nix`. Cursor, goose, copilot, and
pi run without the shared conventions, without the prohibitions, and without
the output style. Cursor instead reads a hand-maintained rule file that has
drifted: `config/cursor-rules/always.mdc` states `openspec 1.3.0` where the
repository is on 1.6.0, and it carries a prohibition the repository no longer
holds.

Pi additionally receives no skills. It implements the Agent Skills standard and
documents the exact setting that would point it at the populated tree, and that
setting is unset.

## What Changes

- Generate a global context file for cursor, goose, copilot, and pi at each
  one's documented global path, from the same `instructions.nix` source every
  other harness uses.
- Generate the cursor MDC rule bodies from `instructions.nix` instead of
  maintaining them by hand. The MDC frontmatter stays authored.
- Register `~/.claude/skills` as pi's skills root through pi's `skills`
  setting.
- Add a build assertion. Every configured harness must resolve to a context
  path and a skills root, or be declared exempt in one place with a stated
  reason.

### Non-goals

- Changing the content of the shared instructions. This change moves the
  existing text to four more harnesses and changes no rule.
- Repairing every stale requirement in the `agent-context-files` spec. This
  change corrects the two requirements that the new coverage requirement would
  otherwise contradict: the section list with its line cap, and the Stack
  section. The remaining drift in that spec, including the
  `nix build .#agents-md` target, needs its own change.
- Notification or state-bus work. That belongs to
  `unify-agent-notification-layer`.
- Any harness setting that is not a context path or a skills root. Those belong
  to `modernize-opencode-and-pi-config`.
- Adding a harness.

## Capabilities

### Modified Capabilities

- `agent-context-files`: add a requirement that every configured harness
  receives the generated context or is declared exempt, and correct the
  section-list and line-cap requirement so the capability does not contradict
  itself once the coverage requirement lands.
- `agent-skill-library`: the skills-install requirement names claude, codex,
  gemini, cursor, opencode, and crush. It must name pi, and it must state that
  a harness advertising a skills root must also be able to load from it.
- `cursor-rules-mdc`: the canonical rule set is generated, not hand-written.

## Impact

Modified code:
- `modules/home/programs/llm/lib/instructions.nix`
- `modules/home/programs/llm/lib/harness-kit.nix`
- `modules/home/programs/llm/config/cursor.nix`
- `modules/home/programs/llm/config/goose.nix`
- `modules/home/programs/llm/config/copilot-cli.nix`
- `modules/home/programs/llm/config/pi.nix`
- `modules/home/programs/llm/config/cursor-rules/always.mdc`

Dependencies:
- Depends on `modernize-opencode-and-pi-config` phase 2 for the pi retired-key
  mechanism. Pi's `skills` array reaches disk through a deep merge that never
  removes a key, so rolling this change back needs that mechanism. Land it
  first, or accept that pi's skills setting cannot be rolled back.

Impactful and irreversible actions:
- `nh darwin switch` applies the new context files to the live machine.
- Deleting the hand-written body of `always.mdc` removes text that is not
  recoverable from the generator, because the generator never produced it.
  Capture the delta before deleting.

Gating signal:
- `nix flake check`, then `nh darwin build`, then an owner read of each rendered
  context file, then `nh darwin switch`. Each harness lands on its own. The kill
  switch is removing that harness's `home.file` entry and switching, which
  restores the previous state for that harness alone.
- Pi is the exception. Its `skills` array is not a `home.file` entry; it reaches
  disk through a deep merge that never removes a key. Rolling pi back takes
  three steps: remove the entry, add `skills` to the retired-key list, then
  switch.
