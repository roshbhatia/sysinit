_:

final: _prev:
let
  version = "0.44.0";

  # Platform-specific binary info
  platformInfo = {
    "aarch64-darwin" = {
      platform = "Darwin_arm64";
      hash = "sha256-yRN319nsZaG6qdcv0EErqNRhBkvsqg1n/7TQy9K+j04=";
    };
    "x86_64-darwin" = {
      platform = "Darwin_x86_64";
      hash = "sha256-eB/Eg1dZUSrpBHmxWMS1ydydtVsOM8+tRIT3qQk3jeA=";
    };
    "aarch64-linux" = {
      platform = "Linux_arm64";
      hash = "sha256-QGFFjDHTRx5ACowDO6WF4LLioBZfoxV6knJ1Xr20q2Y=";
    };
    "x86_64-linux" = {
      platform = "Linux_x86_64";
      hash = "sha256-APpcMGuz38PMB2Hr+nKNZisu0NqxZNzHoTuXf2NidR8=";
    };
  };

  info = platformInfo.${final.stdenv.hostPlatform.system} or (throw "Unsupported platform");
in
{
  crush = final.stdenv.mkDerivation {
    pname = "crush";
    inherit version;

    src = final.fetchurl {
      url = "https://github.com/charmbracelet/crush/releases/download/v${version}/crush_${version}_${info.platform}.tar.gz";
      hash = info.hash;
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 crush $out/bin/crush
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
