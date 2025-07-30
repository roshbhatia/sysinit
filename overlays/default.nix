{
  inputs,
  system,
  ...
}:

[
  (import ./packages.nix { inherit inputs system; })
  (import ./nushell-plugins.nix { inherit inputs system; })
]
