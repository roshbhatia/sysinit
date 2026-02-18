# overlays/default.nix
# Purpose: expose overlay list for nixpkgs.
{
  inputs,
  ...
}:
[
  (import ./inputs.nix { inherit inputs; })
  (import ./python-overrides.nix { })
  (import ./crossplane.nix { })
  (import ./kubernetes-zeitgeist.nix { })
  (import ./karabiner-elements.nix { })
  (import ./go-tools.nix { })
  (import ./hererocks.nix { })
  (import ./claude-code.nix { })
  (import ./openspec.nix { })
]
