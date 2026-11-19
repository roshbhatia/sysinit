final: prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.devin-cli) version;

  devinSources = {
    aarch64-darwin = sources.devin-cli.src;
    aarch64-linux = sources.devin-cli-aarch64-linux.src;
    x86_64-linux = sources.devin-cli-x86_64-linux.src;
  };
in
{
  devin-cli = prev.devin-cli.overrideAttrs (
    _finalAttrs: prevAttrs: {
      inherit version;

      src = devinSources.${final.stdenv.hostPlatform.system};

      passthru = prevAttrs.passthru // {
        sources = devinSources;
      };
    }
  );
}
