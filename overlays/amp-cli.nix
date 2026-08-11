final: prev:
# amp ships a new build most days, so nixpkgs' amp-cli runs weeks behind by the
# time a channel bump lands. This overrides the version and the sources and
# keeps every other attribute nixpkgs' derivation sets, because the parts that
# are hard are the parts that do not change: the darwin `install_name_tool`
# relink of `libicucore` plus the `rcodesign` linker-signed re-sign, and
# `autoPatchelfHook` on linux. Reimplementing that here would drift from
# nixpkgs on the next amp packaging change and gain nothing.
let
  sources = final.nvfetcherSources;
  inherit (sources.amp-cli) version;

  # Keyed by nixpkgs system string, because nixpkgs' derivation indexes
  # `passthru.sources` by that name. Only the three platforms nixpkgs itself
  # supports appear; see the comment on the nvfetcher.toml entry.
  ampSources = {
    aarch64-darwin = sources.amp-cli.src;
    aarch64-linux = sources.amp-cli-aarch64-linux.src;
    x86_64-linux = sources.amp-cli-x86_64-linux.src;
  };
in
{
  amp-cli = prev.amp-cli.overrideAttrs (
    _finalAttrs: prevAttrs: {
      inherit version;

      # nixpkgs' derivation reads `src` from `finalAttrs.passthru.sources`, so
      # overriding the set alone would move the build. It is restated here
      # anyway: `overrideAttrs` warns on a version changed without a `src`, and
      # the honest way to quiet that is to name the source, not to set
      # `__intentionallyOverridingVersion`.
      src = ampSources.${final.stdenv.hostPlatform.system};

      # Merged rather than replaced so nixpkgs' `updateScript` survives.
      passthru = prevAttrs.passthru // {
        sources = ampSources;
      };
    }
  );
}
