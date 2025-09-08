{ inputs, system, ... }:
[
  (import ./packages.nix { inherit inputs system; })
  (import ./sbarlua.nix)
  (import ./fix-darwin-bootstrap.nix)
]
