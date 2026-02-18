{
  inputs,
  ...
}:
[
  (import ./inputs.nix { inherit inputs; })
  (import ./python-accelerate.nix { })
  (import ./python-aiohttp.nix { })
  (import ./python-future.nix { })
  (import ./python-setproctitle.nix { })
  (import ./crossplane.nix { })
  (import ./kubernetes-zeitgeist.nix { })
  (import ./karabiner-elements.nix { })
  (import ./go-enum.nix { })
  (import ./gomvp.nix { })
  (import ./json-to-struct.nix { })
  (import ./gojsonstruct.nix { })
  (import ./hererocks.nix { })
  (import ./claude-code.nix { })
  (import ./openspec.nix { })
]
