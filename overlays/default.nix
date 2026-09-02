{
  inputs,
  ...
}:
[
  (_final: prev: {
    sunshine =
      if prev.stdenv.hostPlatform.isLinux then
        (prev.sunshine.override {
          cudaSupport = true;
          cudaPackages = prev.cudaPackages.overrideScope (_: _: { cuda_compat = null; });
        }).overrideAttrs
          (old: {
            appendRunpaths = (old.appendRunpaths or [ ]) ++ [ "/run/opengl-driver/lib" ];
          })
      else
        prev.sunshine;
  })
  (import ./nvfetcher-sources.nix)
  (import ./inputs.nix { inherit inputs; })
  (import ./meat.nix { inherit inputs; })
  (import ./hermes-agent.nix { inherit inputs; })
  (import ./sysinit-gotools.nix { inherit inputs; })
  (import ./calldiff.nix)
  (import ./python313.nix)
  (import ./kubernetes-zeitgeist.nix)
  (import ./go-enum.nix)
  (import ./gomvp.nix)
  (import ./vale-styles.nix)
  (import ./mermaid-ascii.nix)
  (import ./pretty-mermaid.nix)
  (import ./hererocks.nix)
  (import ./openspec)
  (import ./pi-coding-agent.nix)
  (import ./atomic-coding-agent.nix)
  (import ./prime-agent.nix)
  (import ./amp-cli.nix)
  (import ./crush.nix)
  (import ./fx.nix)
  (import ./contextive.nix)
  (import ./ioskeleyMono.nix)
  (import ./wumpusMono.nix)
  (import ./bookerly.nix)
  (import ./codex.nix)
  (import ./acp-amp.nix)
  (import ./codex-acp.nix)
  (import ./localias.nix)
  (import ./alerter.nix)
  (import ./sheets.nix)
  (import ./zoetrope.nix)
  (
    final: prev:
    let
      pristine = import inputs.nixpkgs {
        inherit (final.stdenv.hostPlatform) system;
        inherit (final) config;
      };
    in
    {
      # mise's test suite shares a mutex across parallel tests. One Range-header
      # assertion in src/http.rs fails and poisons it, and 31 more tests then die
      # with PoisonError. The tests only re-ran because a usage 4.0.0 -> 5.1.0
      # bump changed the drv hash; mise's own source did not move.
      #
      # Cache audit: the pristine output is on neither cache.nixos.org nor
      # roshbhatia.cachix.org, so this builds from source either way and the
      # override costs no substitution.
      #
      # Upstream gates cmake, nss-cacert, git and rust-bindgen-hook on doCheck,
      # but libz-ng-sys needs cmake in buildPhase too. mise uses the finalAttrs
      # pattern, so overrideAttrs re-reads that list under the new doCheck and
      # `old.nativeBuildInputs` returns the reduced one. Read it off the
      # unoverridden package instead, which names no input by hand.
      mise = pristine.mise.overrideAttrs (_: {
        doCheck = false;
        inherit (pristine.mise) nativeBuildInputs;
      });
      electron_41 = if prev.stdenv.hostPlatform.isDarwin then prev.electron_41 else pristine.electron_41;
      electron = if prev.stdenv.hostPlatform.isDarwin then prev.electron else pristine.electron;
    }
  )
]
