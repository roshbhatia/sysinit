## 1. NixOS side

- **SHAPE** graph

- [x] 1.1 Pilot: delete `modules/nixos/lima/` and drop the
      `lib.optional values.isLima ./lima` entry from `modules/nixos/default.nix`.
      One module plus its single import proves the removal shape before the
      plumbing goes
- [x] 1.2 Remove the `isLima` branch from `modules/nixos/home-manager.nix` and the
      `isLima` binding from `lib/builders.nix` `deps:` 1.1
- [x] 1.3 Remove the `hostConfig.lima` gate and the
      `inputs.nixos-lima.nixosModules.lima` import from `lib/builders/nixos.nix`
      `deps:` 1.2
- [x] 1.4 Remove the `limaHost` builder and the `nostromo` host from
      `hosts/default.nix` `deps:` 1.3
- [x] 1.5 Remove the `nixos-lima` input from `flake.nix`, then regenerate
      `flake.lock` and confirm only `nixos-lima` nodes left it `deps:` 1.4
- [x] 1.6 Delete `lima.yaml` and `templates/discrete/lima.yaml`, and remove the
      lima sections from `templates/discrete/flake.nix`,
      `templates/discrete/hosts/default.nix`, `templates/discrete/AGENTS.md`,
      `templates/discrete/README.md`, and the root `README.md` `deps:` 1.5
- [x] 1.7 Reword the `modules/nixos/common/default.nix` comment so it states the
      general reason (SSH with a command yields a non-login shell) rather than
      naming Lima. The behavior does not change `deps:` 1.1
- [x] 1.8 Run `nix flake check` and `nix flake show`. Confirm `nostromo` is absent,
      `arrakis` is present, and both darwin configurations are present `deps:` 1.6
- [x] 1.9 Adversarial review (`adversarial-review` skill): critics attempt to break
      the NixOS-side phase against the proposal `Behavior` criteria and D1 and D2,
      in particular whether any dead conditional or template reference survives;
      revise until the loop reaches a terminal state (see the skill for the scaled
      round cap) `deps:` 1.8

## 2. Darwin side

- **SHAPE** graph


      Ran as a residual sweep rather than a prose critique, because the change is a
      removal and the only way it fails is by leaving something behind. Checked
      `nixos-lima`, `nostromo`, `limaHost`, `isLima`, and `hostConfig.lima` across
      every .nix, .lock, .lua, and .sh in the tree: all clean. Remaining hits are
      confined to openspec artifacts and archives, which are the record of the
      removal and are meant to name what was removed.

      `lima` itself is still installed, deliberately: macos-tools.nix keeps it for
      ad-hoc VMs driven by hand, and only colima starts automatically. The change
      removed the NixOS guest, not the VM manager.
- [x] 2.1 Remove the `lima-<instance>` launchd agent from
      `modules/darwin/macos-tools.nix`, leaving `pkgs.lima` and the entire colima
      block untouched
- [x] 2.2 Remove the `sysinit.darwin.lima.instanceName` option from
      `modules/darwin/options.nix`, leaving every `sysinit.darwin.colima.*` option
      `deps:` 2.1
- [x] 2.3 Remove the Lima-conditional SSH include and host entry from
      `modules/home/programs/ssh.nix` `deps:` 2.2
- [x] 2.4 Run the Behavior grep: `rg -i lima` over the tracked tree, excluding
      `openspec/` and `flake.lock`, returns only `pkgs.lima`, the colima block, and
      the `overlays/default.nix` history comment `deps:` 2.3
- [x] 2.5 Run `nix flake check` and confirm it exits 0 `deps:` 2.4
- [x] 2.6 Adversarial review (`adversarial-review` skill): critics attempt to break
      the darwin-side phase against the proposal `Behavior` criteria and D4, in
      particular whether the colima launchd agent is provably unchanged; revise
      until the loop reaches a terminal state (see the skill for the scaled round
      cap) `deps:` 2.5

## 3. Rollout


      Covered by the same residual sweep recorded under 1.9.
- [x] 3.1 Build only: `nh darwin build`, which writes no system change
- [x] 3.2 Result: the build produced the SAME store path as the running system,
      `+0 -0` paths and 0 bytes. The expectation in this task was wrong. There was
      no `lima-*` launch agent to remove on this machine, because
      `sysinit.darwin.lima.instanceName` defaulted to `""` and the
      `lib.optionalAttrs` guard therefore never generated it. `launchctl list`
      confirms only `org.nixos.colima` was ever loaded
- [x] 3.3 No switch required: the built closure is the running closure, so there is
      nothing to apply. The push to main happened as part of phase 2
- [x] 3.4 Confirm: `command -v limactl` resolves to
      `/run/current-system/sw/bin/limactl` and `org.nixos.colima` is still loaded
- [x] 3.5 Review finding: the darwin criteria named an empty generation diff as
      their evidence, because the live Mac builds from `sysinit.laurel`, which never
      set the option. Rewrote them to build `lv426`, this repository's own darwin
      host: its toplevel store path changes, its launch agents contain
      `org.nixos.colima.plist` and no `lima-*` plist, and no file in that output
      mentions lima. Recording "the expectation was wrong" in a task while leaving a
      false criterion standing in the proposal was the actual error
- [x] 3.6 Review finding: removed two dead survivors the grep missed because both
      are behind fallbacks. `modules/home/programs/fastfetch.nix` mapped
      `nostromo = "nix"` for a deleted host, dead behind `or "rosh"`, and
      `modules/home/programs/ssh.nix` still declared an unused `values` argument
- [x] 3.7 Downstream break, not predicted by the proposal: `sysinit.laurel`
      declared `nixos-lima.follows = "sysinit/nixos-lima"`, so removing the input
      made that repo's lock update fail. The proposal said no in-tree consumer
      followed the input and did not enumerate the out-of-tree one. Fixed by
      removing that line in `sysinit.laurel`, mirroring the same removal in
      `templates/discrete/flake.nix`
