_:

final: _prev:
let
  sources = final.nvfetcherSources;
  version = sources.crush.version;

  platformInfo = {
    "aarch64-darwin" = {
      platform = "Darwin_arm64";
      src = sources.crush.src;
    };
    "x86_64-darwin" = {
      platform = "Darwin_x86_64";
      src = sources.crush-x86_64-darwin.src;
    };
    "aarch64-linux" = {
      platform = "Linux_arm64";
      src = sources.crush-aarch64-linux.src;
    };
    "x86_64-linux" = {
      platform = "Linux_x86_64";
      src = sources.crush-x86_64-linux.src;
    };
  };

  info = platformInfo.${final.stdenv.hostPlatform.system} or (throw "Unsupported platform");
in
{
  crush = final.stdenv.mkDerivation {
    pname = "crush";
    inherit version;

    inherit (info) src;

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 crush_${version}_${info.platform}/crush $out/bin/crush
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "A shared key-value store for the terminal";
      homepage = "https://github.com/charmbracelet/crush";
      license = licenses.mit;
      mainProgram = "crush";
    };
  };
}
