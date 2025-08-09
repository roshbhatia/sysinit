{ inputs, system, ... }:
[
  (import ./packages.nix { inherit inputs system; })
  (import ./vscode-insiders.nix)
]

