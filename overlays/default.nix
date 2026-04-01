{
  inputs,
  ...
}:
[
  (import ./nvfetcher-sources.nix { })
  (import ./inputs.nix { inherit inputs; })
  (import ./python311.nix { })
  (import ./python313.nix { })
  (import ./crossplane.nix { })
  (import ./kubernetes-zeitgeist.nix { })
  (import ./go-enum.nix { })
  (import ./gomvp.nix { })
  (import ./hererocks.nix { })
  (import ./openspec.nix { })
  (import ./deno.nix { })
  (import ./pi-coding-agent.nix { })
  (import ./crush.nix { })
  (import ./ast-grep.nix { })
  (import ./opa.nix { })
  (import ./ioskeleyMono.nix { })
  (import ./commitMono.nix { })
  (import ./wumpusMono.nix { })
  (import ./direnv.nix { })
  (import ./ginkgo.nix { })
  (import ./goose-cli.nix { })
  (import ./mozilla.nix { inherit inputs; })
]
