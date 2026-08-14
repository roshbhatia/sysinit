final: prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.amp-cli) version;

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

      src = ampSources.${final.stdenv.hostPlatform.system};

      passthru = prevAttrs.passthru // {
        sources = ampSources;
      };
    }
  );
}
