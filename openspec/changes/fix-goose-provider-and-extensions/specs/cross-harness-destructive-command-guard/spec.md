## REMOVED Requirements

### Requirement: Goose denies destructive commands via shell.deny

**Reason**: Goose 1.28 has no command-pattern deny surface. The requirement
described a mechanism that does not exist.

Verified against the installed binary: with `shell.deny: ["echo"]` and
`GOOSE_MODE: auto`, goose still ran `echo`. Neither `shell.allow` nor
`shell.deny` appears anywhere in goose's config handling; goose preserves the
keys as unrecognized YAML and ignores them. Goose's only permission surface is
tool-level (`permission.yaml`, keyed by names such as `developer__shell`) plus
the `GOOSE_MODE` risk classifier.

**Migration**: `formatForGoose` and `formatDestructiveForGoose` are deleted from
`lib/allowlist.nix`, and `goose.nix` no longer emits a `shell` block. Goose
keeps `GOOSE_MODE = "smart_approve"`, which prompts on higher-risk actions. This
is weaker than the regex guard the other harnesses carry, and is a known gap
rather than an equivalent replacement. Revisit if goose adds a pre-tool hook.
