{
  inputs,
  system,
  ...
}:

[
  (import ./packages.nix { inherit inputs system; })
]
