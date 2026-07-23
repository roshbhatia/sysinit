## Why

Today `rosh-spec-driven` resolves only inside this repo. `openspec schema which rosh-spec-driven` reports `Source: project`, and the CLI hardcodes `DEFAULT_OPENSPEC_SCHEMA = 'spec-driven'`. Any other project on the machine, and every bare `openspec init`, falls back to upstream `spec-driven`. The user's authoring rules (reuse-check, progressive rollout, negative scenarios, adversarial review) apply nowhere but sysinit. Make the fork the default that every project on the machine resolves and inherits.

## What Changes

- Install the forked schema to the XDG user-override directory (`$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven/`) through home-manager, so `openspec` resolves it in every project as `Source: user`. This is Lever 1.
- Patch every default-schema assignment site in the built openspec `dist/` (six sites in openspec 1.6.0, including the inline `defaultSchema: 'spec-driven'` in `root-selection.js` that `openspec new change` actually reads) from `spec-driven` to `rosh-spec-driven`, via `overlays/openspec.nix`. The patch MUST fail the build on a missed site (`--replace-fail` or a match-count guard). This is Lever 2. **BREAKING** for any workflow that relied on the upstream default outside sysinit.
- Add a `dist/` assertion (in `nix flake check` or a build check) that the effective default resolves to `rosh-spec-driven`, because `hack/sync-openspec-schema.sh` only diffs schema template files and never inspects `dist/*.js`. Record the patch in `openspec/schemas/rosh-spec-driven/CHANGES.md`.
- Document the shared-repo practice in `AGENTS.md`: in a repo shared with others, pin `schema: spec-driven` or run `openspec init --schema spec-driven`, because the fork is not distributed. No commit-time guard is added; it was judged not worth the cost for a single user, and a teammate who pulls the fork name gets an explicit "schema not found" error rather than silent misbehavior.
- Update `AGENTS.md` and `modules/home/programs/llm/lib/instructions.nix` to state the machine-wide default.

### Non-goals

- Publishing the schema to a Git URL or registry for other machines.
- Changing the schema's authoring rules; the citation rule ships in `add-citation-verification`.
- Vendoring copies of the schema into other repos' `openspec/schemas/`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `openspec-customization`: add requirements for machine-wide resolution (XDG user override) and for the patched default-schema constant.

## Impact

- Affected files: `overlays/openspec.nix` (postPatch), a home-manager module under `modules/home/programs/llm/` (new `xdg.dataFile` install), `hack/sync-openspec-schema.sh`, `openspec/schemas/rosh-spec-driven/CHANGES.md`, `AGENTS.md`, `modules/home/programs/llm/lib/instructions.nix`.
- Impactful actions that need human-verification checkpoints in `tasks.md`:
  - `nh darwin switch`: installs the schema to the XDG data dir and rebuilds the openspec overlay closure.
  - Rebuild of the openspec derivation: the postPatch changes the source, so the closure hash changes.
  - No network writes.
- Gating signal: `nix flake check` (validate) then `nh darwin build` (no system change) then a user spot-check then `nh darwin switch`. Lever 1 is a prerequisite for Lever 2: the patched default must resolve from the XDG dir before a fresh `openspec init` can succeed.
