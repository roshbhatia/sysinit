## 1. NixOS side

- **SHAPE** graph

- [ ] 1.1 Pilot: delete `modules/nixos/lima/` and drop the
      `lib.optional values.isLima ./lima` entry from `modules/nixos/default.nix`.
      One module plus its single import proves the removal shape before the
      plumbing goes
- [ ] 1.2 Remove the `isLima` branch from `modules/nixos/home-manager.nix` and the
      `isLima` binding from `lib/builders.nix` `deps:` 1.1
- [ ] 1.3 Remove the `hostConfig.lima` gate and the
      `inputs.nixos-lima.nixosModules.lima` import from `lib/builders/nixos.nix`
      `deps:` 1.2
- [ ] 1.4 Remove the `limaHost` builder and the `nostromo` host from
      `hosts/default.nix` `deps:` 1.3
- [ ] 1.5 Remove the `nixos-lima` input from `flake.nix`, then regenerate
      `flake.lock` and confirm only `nixos-lima` nodes left it `deps:` 1.4
- [ ] 1.6 Delete `lima.yaml` and `templates/discrete/lima.yaml`, and remove the
      lima sections from `templates/discrete/flake.nix`,
      `templates/discrete/hosts/default.nix`, `templates/discrete/AGENTS.md`,
      `templates/discrete/README.md`, and the root `README.md` `deps:` 1.5
- [ ] 1.7 Reword the `modules/nixos/common/default.nix` comment so it states the
      general reason (SSH with a command yields a non-login shell) rather than
      naming Lima. The behavior does not change `deps:` 1.1
- [ ] 1.8 Run `nix flake check` and `nix flake show`. Confirm `nostromo` is absent,
      `arrakis` is present, and both darwin configurations are present `deps:` 1.6
- [ ] 1.9 Adversarial review (`adversarial-review` skill): critics attempt to break
      the NixOS-side phase against the proposal `Behavior` criteria and D1 and D2,
      in particular whether any dead conditional or template reference survives;
      revise until the loop reaches a terminal state (see the skill for the scaled
      round cap) `deps:` 1.8

## 2. Darwin side

- **SHAPE** graph

- [ ] 2.1 Remove the `lima-<instance>` launchd agent from
      `modules/darwin/macos-tools.nix`, leaving `pkgs.lima` and the entire colima
      block untouched
- [ ] 2.2 Remove the `sysinit.darwin.lima.instanceName` option from
      `modules/darwin/options.nix`, leaving every `sysinit.darwin.colima.*` option
      `deps:` 2.1
- [ ] 2.3 Remove the Lima-conditional SSH include and host entry from
      `modules/home/programs/ssh.nix` `deps:` 2.2
- [ ] 2.4 Run the Behavior grep: `rg -i lima` over the tracked tree, excluding
      `openspec/` and `flake.lock`, returns only `pkgs.lima`, the colima block, and
      the `overlays/default.nix` history comment `deps:` 2.3
- [ ] 2.5 Run `nix flake check` and confirm it exits 0 `deps:` 2.4
- [ ] 2.6 Adversarial review (`adversarial-review` skill): critics attempt to break
      the darwin-side phase against the proposal `Behavior` criteria and D4, in
      particular whether the colima launchd agent is provably unchanged; revise
      until the loop reaches a terminal state (see the skill for the scaled round
      cap) `deps:` 2.5

## 3. Rollout

- [ ] 3.1 Build only: `nh darwin build`, which writes no system change
- [ ] 3.2 Confirm: the owner reads the generation diff and decides whether the only
      launch-agent change is the `lima-*` removal, with every colima path identical
- [ ] 3.3 Apply: push to main, then `nh darwin switch`, gated on `nix flake check`
      and `nh darwin build` exiting 0 and on 3.2 being confirmed
- [ ] 3.4 Confirm: the owner checks that `command -v limactl` still resolves and
      that the colima agent is still loaded, which is the judgment no check here
      can make
