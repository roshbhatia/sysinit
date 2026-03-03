_:

final: _prev:
let
  version = "0.55.4";
  baseUrl = "https://github.com/badlogic/pi-mono/releases/download/v${version}";

  platformInfo = {
    "aarch64-darwin" = {
      asset = "pi-darwin-arm64.tar.gz";
      hash = "sha256-hU6H6oW7il3TYCR6CC9FdehM54nASHPNnPrbnV3aSm8=";
    };
    "x86_64-darwin" = {
      asset = "pi-darwin-x64.tar.gz";
      hash = "sha256-IO/N38B6TSQq9OIhWKsWP54qnSFb7HfXCpzHqOHO54w=";
    };
    "aarch64-linux" = {
      asset = "pi-linux-arm64.tar.gz";
      hash = "sha256-XnIU0NfCp2l02/AMUKsf5doTEwr7OpkKm4BQ+eAZ1wE=";
    };
    "x86_64-linux" = {
      asset = "pi-linux-x64.tar.gz";
      hash = "sha256-rQbmI93JgQ9pAxsCXWO/y4BPyY4Meuy5+c4V7KblzvI=";
    };
  };

  info =
    platformInfo.${final.stdenv.hostPlatform.system}
      or (throw "pi-coding-agent: Unsupported platform ${final.stdenv.hostPlatform.system}");
in
{
  pi-coding-agent = final.stdenv.mkDerivation {
    pname = "pi-coding-agent";
    inherit version;

    src = final.fetchurl {
      url = "${baseUrl}/${info.asset}";
      inherit (info) hash;
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp -r pi $out/
      ln -s $out/pi/pi $out/bin/pi
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://github.com/badlogic/pi-mono";
      license = licenses.mit;
      mainProgram = "pi";
    };
  };
}
