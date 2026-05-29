_:

final: _prev:
let
  version = "1.39.3";
  srcs = {
    "aarch64-darwin" = final.fetchurl {
      url = "https://github.com/777genius/claude-notifications-go/releases/download/v${version}/claude-notifications-darwin-arm64";
      hash = "sha256-njrO2ifItdmpf8TLByW03uMzdgffgrZsK9Y7LjRT5MI=";
    };
  };
  src =
    srcs.${final.stdenv.hostPlatform.system}
      or (throw "claude-notifications-go: unsupported platform ${final.stdenv.hostPlatform.system}");
in
{
  claude-notifications-go = final.stdenv.mkDerivation {
    pname = "claude-notifications-go";
    inherit version src;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp $src $out/bin/claude-notifications
      chmod +x $out/bin/claude-notifications
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Smart desktop notifications for Claude Code";
      homepage = "https://github.com/777genius/claude-notifications-go";
      license = licenses.gpl3;
      mainProgram = "claude-notifications";
    };
  };
}
