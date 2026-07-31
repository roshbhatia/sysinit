## Context

Both harness configs already use the merge-into-a-writable-file pattern,
because both tools write their own config at runtime.
`config/opencode.nix:221` merges with `jq` and `config/pi.nix:578` does the
same. That pattern stays. What changes is which keys each merge declares and
which file each key lands in.

The facts this change responds to were read from the installed builds, not from
vendor documents:

- `pkgs.opencode` is 1.18.4 and ships `share/opencode/config.json` and
  `share/opencode/tui.json`. The `Config` definition sets
  `additionalProperties: false` and its property list contains no `theme`, no
  `keybinds`, and no `tui`. Those three appear in the TUI schema instead.
- `~/.config/opencode/opencode.json.tui-migration.bak` exists on the live
  machine, so the migration has already run once.
- `pkgs.pi-coding-agent` is 0.82.1 and ships its own docs and its own
  `examples/extensions` tree. `config/pi.nix:8` pins a separate revision whose
  `packages/coding-agent/package.json` reports 0.74.0.
- A string scan of the installed pi binary finds `quietStartup`,
  `defaultThinkingLevel`, `externalEditor`, and `enableInstallTelemetry`, and
  finds no `showLastPrompt`.
- The live `~/.pi/agent/settings.json` holds `defaultProvider`,
  `defaultModel`, `defaultThinkingLevel`, `hideThinkingBlock`,
  `shellCommandPrefix`, `theme`, and `powerline`, none of which `pi.nix`
  declares.

Patterns reused: the hermetic `pkgs.runCommand` checks at `flake.nix:229` are
the shape for the schema validation and for the key-presence scan. The
build-time `throw` at `config/cursor.nix:43`, consumed at `config/cursor.nix:58`,
is the shape for the unselected-theme assertion.

An earlier draft of this design cited `_gateConflictCheck` at
`config/pi.nix:491` as the assertion pattern. That citation was wrong twice
over. First, it compares two Nix-level lists at evaluation time and never reads
a derivation's contents, so it cannot model the key-presence scan; that scan
must read the built pi binary, which evaluation cannot do without
import-from-derivation, so it is a check derivation. Second,
`_gateConflictCheck` is a `let` binding that the module body never references.
Nix is lazy, so it is never forced and its `throw` can never fire. It is dead
code and this repository has been carrying a permission-gate assertion that
does not run.

Repairing `_gateConflictCheck` is not in this change's scope. It is recorded in
Open Questions so it is not lost, and no task in this change cites it as a
pattern.

New dependency introduced: a JSON-schema validator. No flake input provides
one today. `pkgs.check-jsonschema` is available in nixpkgs and is the
candidate.

## Goals / Non-Goals

Goals:

- The rendered config for each harness is accepted by the installed build.
- A future upstream key move fails the build, not the runtime.
- Nix owns every pi setting this repository has an opinion about.
- One source supplies the pi binary and the pi extension files.

Non-goals:

- Choosing pi's provider, model, or thinking level.
- Notification, state-bus, context-file, and skills-root work.
- Any harness other than opencode and pi.
- OpenCode custom commands, references, the headless server, and skill URLs.

## Decisions

### D1. Schema validation runs against the installed derivation

The check reads the schema out of `${pkgs.opencode}/share/opencode/` and
validates the rendered JSON against it inside a `nix flake check` derivation.
Because the schema comes from the same derivation as the binary, a version bump
moves both together and a key move is caught by the bump itself.

- Alternative rejected: vendor a copy of the schema into this repository and
  validate against that. Rejected because the copy would need its own drift
  check, which is the problem the check exists to solve, one layer up.

### D2. Pi settings are declared exhaustively, and declared keys win

Today the merge is `jq -s '.[0] * .[1]'`, so the Nix base already wins for the
keys it declares. The defect is that it declares three keys, one of which is
dead. The fix is the declaration, not the merge.

Every key the repository has an opinion about is declared. The keys that are
owner preference stay undeclared and keep being preserved from the runtime
file.

- Alternative rejected: replace the settings file outright on every activation.
  Rejected because pi stores session bookkeeping such as
  `lastChangelogVersion` there, and discarding it would make pi re-run its
  first-run paths after every switch.

### D3. A dead key is a build failure, not a comment

`showLastPrompt` shipped in this repository and in the `pi-extension-config`
spec, and neither caught that the installed binary does not know it. A string
scan of the installed binary for each declared key turns that class of error
into a build failure.

The scan is a presence check, not a schema check. Pi ships no settings schema,
so presence of the key name in the binary is the strongest available signal. A
false positive is possible and is acceptable; a false negative is what this
guards against.

The scan runs as a `nix flake check` derivation, not as a module-level `throw`.
It must read the contents of the built pi binary, and evaluation cannot do that
without import-from-derivation, which would force a realization of
`pi-coding-agent` on every evaluation of the module.

- Alternative rejected: parse pi's bundled `docs/settings.md` and check the
  declared keys against its table. Rejected because the table is prose that can
  lag the binary, while the binary is the thing that reads the key.

### D4. Extension files come from the installed pi package

`${pkgs.pi-coding-agent}/pi/examples/extensions/` holds the same file set the
pinned revision holds, at the version the binary actually runs. Sourcing from
there deletes one fetcher, one revision, one hash, and the skew between them.

- Alternative rejected: bump the pinned revision to match 0.82.1 and keep the
  fetcher. Rejected because it fixes today's skew and leaves the mechanism that
  produced it, so the next pi bump reintroduces it.

### D5. `nvim-pi` is wired or removed, and the decision is forced in this change

`config/pi.nix:524` builds `nvim-pi` and `config/pi.nix:590` installs it, while
the keybindings file sets `externalEditor` to null, which unbinds the only key
that would launch it. It is currently unreachable either way.

- Alternative rejected: leave it installed and undecided. Rejected because an
  unreachable binary in the profile reads as a working feature to the next
  reader, which is the same failure mode as the dead settings key.

### D6. Stale runtime directories are listed for the owner, not deleted silently

`~/.config/opencode/plugins/` and `~/.config/opencode/tools/` hold untracked
files under names OpenCode does not read. They are listed for the owner and
removed only after confirmation.

- Alternative rejected: delete them during activation. Rejected because the
  repository's own rules forbid destructive action on files outside the
  scratch space without explicit instruction.

## Rollout & Gating

Three slices.

1. OpenCode. Move the TUI keys, add the schema check, declare the new Config
   keys. Gate: the schema check passes for both files, and OpenCode starts once
   without writing a new migration backup.
2. Pi settings ownership. Capture the live file, declare the key set, remove
   the dead key, select the theme, add the presence assertion. Gate: the owner
   reviews the captured file and confirms which drifted values Nix should take
   over.
3. Pi extension source and the new extensions. Gate: pi starts and lists every
   vendored extension without a load error.

Default sequence: edit, `nix flake check`, `nh darwin build`, owner spot-check,
`nh darwin switch`. No deviation.

Kill switch: revert the slice's commit, run `nh darwin switch`, and only then
restore the captured settings file. Restoring the file alone does not work. The
activation merge runs on every switch, so any later `nh darwin switch` for an
unrelated reason re-imposes every key the reverted slice declared. The captured
file is the second half of the rollback, never the whole of it.

A key the slice added and the revert undeclares also needs an entry in the
retired-key list, because a deep merge cannot remove a key on its own.

## Risks / Trade-offs

- Taking ownership of `defaultProvider` and `defaultModel` would overwrite the
  owner's live choice. Mitigation: those two stay undeclared in this change and
  are raised as an open question. Flagged as a human-verification checkpoint in
  slice 2.
- The key-presence scan can pass on a key that is only a substring of an
  unrelated identifier. Mitigation: the scan is a guard against a key that is
  wholly absent, which is the observed failure; a stricter check is not
  available while pi ships no settings schema.
- Sourcing extensions from the pi package couples the extension set to the pi
  version. A pi bump can remove an extension this repository names. Mitigation:
  the missing-extension build failure in the spec makes that a build error with
  the name, not a silent drop.
- The new pi extensions change interactive behavior. `plan-mode` adds a
  keybinding, `modal-editor` changes editing, and `protected-paths` blocks
  writes. Mitigation: each is added in slice 3 and confirmed on a live session
  before the slice is marked done. `protected-paths` must be checked against
  the existing permission gate for overlap.
- The OpenCode schema check adds a JSON-schema validator to the check closure.
  No flake input provides one today; this was confirmed, not assumed.
  Mitigation: slice 1 adds `pkgs.check-jsonschema` explicitly as a new
  dependency and records it in the proposal Impact rather than discovering the
  gap at execution time.

## Migration Plan

1. Verify: `nix flake check` passes before any edit. Copy the live
   `~/.pi/agent/settings.json` and `~/.config/opencode/opencode.json` into the
   change directory.
2. Apply slice 1. Confirm: the schema check is green, and OpenCode starts
   without writing a new migration backup.
3. Verify: the owner reads the captured pi settings and names which keys Nix
   takes over. Apply slice 2 and switch. Confirm: the merged file carries the
   Nix values, the stylix theme is active, and pi's session bookkeeping keys
   survive.
4. Verify: `nh darwin build` is green with the package-sourced extensions.
   Apply slice 3 and switch. Confirm: pi lists every extension with no load
   error, and the new extensions behave as expected on one live session.
5. Verify: list the stale OpenCode directories for the owner. Apply: remove
   them only after the owner confirms. Confirm: OpenCode still starts.

Rollback, in this order: revert the slice's commit, add any key the revert
undeclares to the retired-key list, run `nh darwin switch`, then restore the
captured settings file. Restoring the file first is wrong; the next activation
re-imposes the declared keys over it.

## Adversarial Review

Rubric: the spec scenarios in this change including every negative one, the
Decisions above, the Rollout & Gating slice gates, and the proposal Non-goals.

The deterministic half is mandatory. `specutil check` runs on every slice.

The critic half is default-on and owner-gated. The `adversarial-review` skill
elicits approve or deny; the owner may waive it for a small slice, recorded as
`Adversarial review: waived by owner`. When run, independent critics attempt to
break the slice with a concrete failing scenario that names a violated rubric
item. The author revises against surviving objections. The loop repeats until
no objection survives or K=4 rounds. Under Claude Code the critics are
in-process teammates. See the `adversarial-review` skill for the methodology.

## Open Questions

- Should Nix own pi's `defaultProvider` and `defaultModel`? The live values are
  `openrouter` and `openrouter/free`. Every other harness has its model
  declared in Nix. The owner decides in slice 2.
- Is `powerline` a real pi setting? It is in the live file and is absent from
  the bundled `docs/settings.md`. The key-presence scan in slice 2 answers it.
- Does `protected-paths` conflict with `@gotgenes/pi-permission-system`, which
  already owns tool-call interception? Slice 3 checks this before vendoring.
- Wire `externalEditor` to `nvim-pi`, or remove `nvim-pi`? The owner decides in
  slice 3.
- `_gateConflictCheck` at `config/pi.nix:491` is dead code. It is a `let`
  binding the module body never references, so its `throw` has never been able
  to fire. The permission-gate conflict it claims to prevent is currently
  unguarded. Repair is out of scope here and needs its own change.
