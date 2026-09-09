# Cloud agent environments

This repository ships a trimmed profile of the user's own CLIs for cloud coding
agents. The profile is the `cloudTools` flake package: a `symlinkJoin` over
`ask`, `gate`, `changes`, `traces`, `orc`, `seshy`, `specutil`, `calldiff`, and
the `sysinit-utils` helpers. Every component is in `cacheAttrs`, so the closure
substitutes wholesale from `roshbhatia.cachix.org` with no source build.

`hack/cloud-setup.sh` is the one installer. It installs Determinate Nix, adds
the cachix substituter, builds
`github:roshbhatia/sysinit#packages.x86_64-linux.cloudTools`, and links its
`bin/*` into `/usr/local/bin`.

`hack/cloud-setup.sh` and `.cursor/environment.json`
are generated from `modules/shared/cloud.nix`. Edit the facts there, run
`hack/generate-cloud.sh`, and commit the result; `checks.cloud-files` fails on a
hand edit.

## Claude Code cloud

Claude Code cloud takes its setup script from a UI field, not from a file in the
repository. Paste the setup script there.

1. Open the Claude Code cloud environment settings.
2. In the setup-script (bash) field, paste the full contents of
   `hack/cloud-setup.sh`.
3. Save. The next environment build runs the script and installs the tools.

Keep the pasted copy in step with `hack/cloud-setup.sh`; the field is the source
of truth for Claude Code cloud, so re-paste after you change the script.

## Cursor cloud

`.cursor/environment.json` configures Cursor cloud agents. Its `install` runs
`hack/cloud-setup.sh`. `egressAllowlist` opens the domains the installer needs:
`install.determinate.systems`, `roshbhatia.cachix.org`, `cache.nixos.org`,
`channels.nixos.org`, and `releases.nixos.org`. `egressMode` is
`default_with_network_settings`, so the default domains (GitHub for the flake
fetch) stay reachable alongside the added domains.

Cursor picks the file up automatically. No manual sync is needed.

## Not covered here

`cloudTools` carries no rendered `gate` config. The rendered config bakes
absolute store paths, so a committed copy does not resolve in a cloud box. A box
that needs `gate` configured must regenerate or realise the closure itself. This
is a follow-up, not solved here.
