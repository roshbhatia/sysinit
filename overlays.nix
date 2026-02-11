{
  inputs,
  system,
  ...
}:
[
  (import ./overlays/packages.nix { inherit inputs system; })
  (import ./overlays/weechat-matrix.nix { inherit inputs system; })
]
