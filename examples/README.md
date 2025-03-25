# SysInit Examples

A work system can be configured with it's own Nix configuration using the following:

- `flake.nix`: This should be pretty minimnal, literally just points to the main flake in this repo.
- `config.nix`: Mirrors the config in this repo, but has ovverides for the stuff we want to add on top.
