{ inputs, system, ... }:
[
  (import ./packages.nix { inherit inputs system; })
  (import ./goose-cli.nix)
]

