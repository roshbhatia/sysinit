{
  inputs,
  ...
}:
[
  (import ./inputs.nix { inherit inputs; })
  (import ./python311.nix { })
  (import ./python313.nix { })
  (import ./crossplane.nix { })
  (import ./kubernetes-zeitgeist.nix { })
  (import ./karabiner-elements.nix { })
  (import ./go-enum.nix { })
  (import ./gomvp.nix { })
  (import ./hererocks.nix { })
  (import ./claude-code.nix { })
  (import ./openspec.nix { })
  (import ./wezterm.nix { })
  (import ./crush.nix { })
]
