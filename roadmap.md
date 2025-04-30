# Roadmap

This roadmap outlines the specific steps to optimize the nix configuration, migrate away from Homebrew, and consolidate package management under Nix. After completing each step, run:

    task refresh

to rebuild and apply your configuration, then check off the completed item.

Steps:
- [x] 1. Update flake inputs (nixpkgs, darwin, home-manager) to their latest releases.
- [x] 2. Migrate Homebrew packages into `environment.systemPackages` in `modules/darwin/system.nix`.
- [x] 3. Parameterize `enableHomebrew` via `config.nix` and use it in the Homebrew module.
- [ ] 4. Consolidate Python (pipx), Node (npm), and Go tool installations into Nix/Home-Manager.
- [ ] 5. Refactor `modules/darwin/home/default.nix` to DRY out the dotfile installation logic.
- [ ] 6. Pin nix-darwin and home-manager inputs to specific stable tags instead of `master`.
- [ ] 7. Disable Homebrew entirely (`enableHomebrew = false`) once migrations are confirmed.