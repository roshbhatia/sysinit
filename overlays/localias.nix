final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.localias) version;

  platformInfo = {
    "aarch64-darwin" = {
      inherit (sources.localias) src;
    };
    "x86_64-darwin" = {
      inherit (sources.localias-x86_64-darwin) src;
    };
    "aarch64-linux" = {
      inherit (sources.localias-aarch64-linux) src;
    };
    "x86_64-linux" = {
      inherit (sources.localias-x86_64-linux) src;
    };
  };

  info = platformInfo.${final.stdenv.hostPlatform.system};
in
{
  localias = final.stdenv.mkDerivation {
    pname = "localias";
    inherit version;

    inherit (info) src;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/localias
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Create local domain aliases for development servers";
      homepage = "https://github.com/peterldowns/localias";
      license = licenses.mit;
      mainProgram = "localias";
    };
  };
}
