## Why

The nested NixOS-in-Lima VM is no longer used. It still costs a flake input, a
host definition, a NixOS module tree, a launchd auto-start agent, a darwin
option, two `lima.yaml` files, and conditional branches in five shared files.
Every one of those is a branch a reader has to evaluate and a maintainer has to
keep working.

Lima itself stays useful for ad-hoc VMs, and colima remains the docker backend.
Only the nested-NixOS-guest machinery goes.

## What Changes

- Remove the `nixos-lima` flake input and its `flake.lock` node.
- Remove `modules/nixos/lima/`, the guest module that overrides the upstream
  `nixos-lima` mounts and guest agent.
- Remove the `nostromo` host and the `limaHost` builder from `hosts/default.nix`,
  and the `isLima` / `hostConfig.lima` plumbing from `lib/builders.nix`,
  `lib/builders/nixos.nix`, `modules/nixos/default.nix`, and
  `modules/nixos/home-manager.nix`.
- Remove the `lima-<instance>` launchd auto-start agent from
  `modules/darwin/macos-tools.nix` and the `sysinit.darwin.lima.instanceName`
  option that gates it.
- Remove `lima.yaml`, `templates/discrete/lima.yaml`, and the lima sections of
  the templates and `README.md`.
- Remove the Lima-conditional SSH include and host entry from
  `modules/home/programs/ssh.nix`.
- **BREAKING** `nixosConfigurations.nostromo` stops existing, and
  `sysinit.darwin.lima.instanceName` stops being a valid option.

### Non-goals

- Removing `pkgs.lima`. It stays in `modules/darwin/macos-tools.nix` for ad-hoc
  use.
- Any change to colima: the package, its launchd agent, and every
  `sysinit.darwin.colima.*` option stay exactly as they are.
- Removing the zsh `$SHELL` forcing in `modules/nixos/common/default.nix`. Its
  comment names Lima, but the behavior is correct for any SSH-with-command login.
  Only the comment changes.
- Touching `arrakis`, the real NixOS host.
- The `overlays/default.nix` lima comment, which documents why an override was
  already removed and is still accurate history.

## Behavior

- `nix flake check` exits 0.
- `nix flake show` lists no `nostromo` under `nixosConfigurations`, and still
  lists `arrakis` and both darwin configurations.
- `rg -i lima` over the tracked tree, excluding `openspec/`, `flake.lock`, and the
  two allowed comments named in Non-goals, returns only the `pkgs.lima` package
  entry and the colima block.
- `nixos-lima` appears in neither `flake.nix` nor `flake.lock`.
- The darwin evidence MUST come from building `lv426`, this repository's own darwin
  host, not from `nh darwin build` on the live machine. The live Mac builds from
  `sysinit.laurel`, which never set `sysinit.darwin.lima.instanceName`, so no
  `lima-*` agent was ever generated there and its generation diff is empty. An
  empty diff is not evidence, and an earlier draft of these criteria treated it as
  such.
- `nix build .#darwinConfigurations.lv426.system` succeeds, its toplevel store path
  changes across the change (the removal is real), and its
  `user/Library/LaunchAgents/` contains `org.nixos.colima.plist` and no `lima-*`
  plist.
- No file in `lv426`'s launch-agent output mentions lima, and its generated SSH
  config carries no lima `Include` and no lima host block.
- `pkgs.lima` is still installed: `command -v limactl` resolves.
- The colima launchd agent is unchanged. Compare `lv426`'s
  `org.nixos.colima.plist`, not `sysinit.laurel`'s, because only the former is
  built from this repository.

## Impact

Affected code:
- Removed: `modules/nixos/lima/`, `lima.yaml`, `templates/discrete/lima.yaml`.
- Edited: `flake.nix`, `flake.lock`, `hosts/default.nix`, `lib/builders.nix`,
  `lib/builders/nixos.nix`, `modules/nixos/default.nix`,
  `modules/nixos/home-manager.nix`, `modules/darwin/macos-tools.nix`,
  `modules/darwin/options.nix`, `modules/home/programs/ssh.nix`, `README.md`, and
  the `templates/discrete` copies.

Reuse:
- No new pattern. This is deletion plus the removal of `lib.optional` branches
  that already exist.

Progressive rollout:
- Two phases. First the NixOS side, which cannot affect the running Mac at all.
  Then the darwin side, which touches a launchd agent and so needs a switch.

Impactful and irreversible actions:
- `nh darwin switch` removes a launchd agent. The colima agent must be unaffected,
  which is the one thing worth a human look.
- Removing a flake input rewrites `flake.lock`.
- No `git push` is required before the switch, because this repo's darwin config
  is consumed from the pushed flake by `sysinit.laurel`, so the push must come
  first in practice. That ordering is a task, not an accident.

Gating signal:
- `nix flake check`, then `nh darwin build`, then a generation diff read by the
  owner, then `nh darwin switch`. The kill switch is `git revert` per phase.
