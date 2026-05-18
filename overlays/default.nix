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
  (import ./cocoindex-code.nix { })
  (import ./hermes-agent.nix { inherit inputs; })
  (import ./opa.nix { })
  (import ./ioskeleyMono.nix { })
  (import ./wumpusMono.nix { })
  (import ./bookerly.nix { })
  (import ./direnv.nix { })
  (import ./ginkgo.nix { })
  (import ./codex-acp.nix { })
  (import ./amp-cli.nix { })
  (import ./kvazaar.nix { })
  (import ./goose-cli.nix { })
  (import ./sheets.nix { })
  (import ./mozilla.nix { inherit inputs; })
  (import ./nushell.nix { })
  # openldap-2.6.13 test017-syncreplication-refresh is a timing-sensitive flake
  (_final: prev: {
    openldap = prev.openldap.overrideAttrs (_old: {
      doCheck = false;
    });
  })
]
