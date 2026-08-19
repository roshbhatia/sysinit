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
  (import ./gotools.nix)
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
  (import ./contextive.nix)
  (import ./opa.nix)
  (import ./ioskeleyMono.nix)
  (import ./wumpusMono.nix)
  (import ./bookerly.nix)
  (import ./acp-amp.nix)
  (import ./codex-acp.nix)
  (import ./localias.nix)
  (import ./pplx.nix)
  (import ./alerter.nix)
  (import ./sheets.nix)
  (
    final: prev:
    let
      pristine = import inputs.nixpkgs { inherit (final.stdenv.hostPlatform) system; };
    in
    {
      cargo-watch =
        if prev.stdenv.hostPlatform.isDarwin then
          prev.cargo-watch.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages_latest.lld ];
            RUSTFLAGS = "${old.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld";
          })
        else
          prev.cargo-watch;
      inherit (pristine) mise;
      electron_41 = if prev.stdenv.hostPlatform.isDarwin then prev.electron_41 else pristine.electron_41;
      electron = if prev.stdenv.hostPlatform.isDarwin then prev.electron else pristine.electron;
    }
  )
]
