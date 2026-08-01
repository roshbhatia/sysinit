## Why

Every harness config file has two writers. Nix writes it at activation. The
harness writes it at runtime when the owner changes a setting from inside the
tool. Nix currently installs 14 of those files as read-only store symlinks, so
the harness fails to save. Five harnesses already carry a hand-written
activation script to work around this, and the remaining six are queued behind
the same discovery.

The prose layer has the opposite problem. All 17 skill bodies and
`lib/instructions.nix` contain zero store-path interpolations, so Nix
evaluation adds nothing to them. A one-word edit still costs a full
`nh darwin switch`.

## What Changes

- Add `lib/managed-file.nix`. It writes a harness config file as a real
  writable file and records the applied content as a sidecar base file next to
  it. The next activation does a three-way merge against that base.
- Replace the five bespoke merge and copy scripts in `goose.nix`,
  `opencode.nix`, `pi.nix`, `codex.nix`, and `claude.nix` with calls to the
  helper.
- Convert the read-only symlink targets that a harness writes at runtime into
  managed files. There are 14 candidates; the owner selects the subset in task
  1.2. A target the harness only reads stays a store symlink.
- Delete the hand-maintained `retired`, `authoritative`, and `ownerPreference`
  key lists. The merge base derives all three.
- Add `sysinit-llm-capture <harness>`. It diffs the sidecar base against the
  live file and prints the owner's runtime edits as a Nix attrset on stdout.
- Move the 17 skill bodies from Nix strings to `skills/<name>/SKILL.md` with
  real YAML frontmatter. This removes 16 `''${` escapes and the two-space
  block indent that only exist to survive a Nix string.
- Add `sysinit-llm-render`. It reads the source tree and writes the per-harness
  renders into `$XDG_STATE_HOME/sysinit/llm/skills/<harness>/`. Home Manager
  runs it at activation. The owner runs it directly for a sub-second loop.
- Install each local skill as a per-skill out-of-store directory symlink into
  that state directory, so editing a skill body needs no rebuild.
- **BREAKING**: the skill registry shape changes. `skills/default.nix` stops
  declaring `{ description, content }` attrsets and becomes a directory scan.

### Non-goals

- Moving `lib/instructions.nix` out of Nix. Harness context text is consumed
  through Nix options such as `programs.claude-code.context`, so moving it
  requires reworking every harness config. It is the natural follow-up once
  the skill move proves the renderer.
- Changing which harnesses are installed, which skills exist, or any skill or
  setting content. This change moves and rewires; it does not edit prose or
  flip a setting value.
- Vendored upstream skills from `inputs.specutil` and `inputs.ast-grep-skills`.
  They change only on a lock bump, so rebuild latency is already correct for
  them. They stay as Nix store symlinks.
- Per-host divergence of skills or settings. All three hosts keep one shared
  source.

## Capabilities

### New Capabilities

- `harness-managed-config-files`: harness config files that both Nix and the
  harness write, reconciled by a three-way merge against a recorded base, plus
  the capture path that turns a runtime edit into Nix source.
- `llm-prose-live-edit`: skill source as self-describing Markdown, rendered by
  a standalone renderer, installed so a body edit takes effect without a
  rebuild.

### Modified Capabilities

- `agent-skill-library`: the requirement "Skill registry is the single source
  of truth" currently mandates a `{ description, content }` attrset with the
  body imported from a sibling `.nix` file. The source of truth moves to
  `skills/<name>/SKILL.md` frontmatter plus body.

## Impact

Modified code:
- `modules/home/programs/llm/skills.nix`
- `modules/home/programs/llm/skills/default.nix`
- `modules/home/programs/llm/skills/*.nix` (17 bodies, become `.md`)
- `modules/home/programs/llm/default.nix`
- `modules/home/programs/llm/lib/default.nix`
- `modules/home/programs/llm/config/{goose,opencode,pi,codex,claude}.nix`
- `modules/home/programs/llm/config/{amp,crush,cursor,devin,copilot-cli,gemini}.nix`
- `modules/home/programs/llm/config/opencode-render.nix`
- `modules/home/programs/llm/config/pi-settings-keys.nix`
- `flake.nix` (checks)

New code:
- `modules/home/programs/llm/lib/managed-file.nix`
- `modules/home/programs/llm/lib/frontmatter.nix`
- `modules/home/programs/llm/config/render-skills.sh`
- `modules/home/programs/llm/config/capture-config.sh`

Dependencies: none new. The renderer uses `yq-go` and `jq`, both already in the
closure through `goose.nix` and `opencode.nix`.

Reused patterns:
- `config/notify.nix` already builds shell tools with
  `pkgs.writeShellApplication` and installs them through `home.packages`. Both
  new scripts follow it.
- `config/opencode.nix` already validates a merged file against a schema
  before it moves into place. `managed-file.nix` generalises that step.
- `hack/*.sh` sets the bash conventions: `set -euo pipefail`, and
  `shfmt -i 2 -ci -sr -s`.

Impactful and irreversible actions:
- `nh darwin switch`. The first switch converts the selected read-only
  symlinks into real files and seeds a sidecar base for each. A wrong base
  seeds a wrong merge on every later switch.
- Deleting the 17 `skills/*.nix` bodies. The content moves to `.md`, so a
  botched move loses prose that only git holds.
- Deleting the `retired` and `authoritative` lists in
  `opencode-render.nix` and `pi-settings-keys.nix`. If the derived merge is
  wrong, stale keys return to the live files.
- `git push` to `main`.

Gating signal: `nh darwin build` before `nh darwin switch`. Phase 1 also has a
per-file kill switch. `managed-file.nix` takes an `enable` flag per target, so
a single misbehaving harness reverts to its previous handling without
reverting the phase.
