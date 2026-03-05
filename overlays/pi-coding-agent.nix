_:

final: _prev:
let
  version = "0.56.1";
  baseUrl = "https://github.com/badlogic/pi-mono/releases/download/v${version}";

  platformInfo = {
    "aarch64-darwin" = {
      asset = "pi-darwin-arm64.tar.gz";
      hash = "sha256-//3ibdy5FCIUaD8SsANOe46vw27y9c5O95XK7416+Zc=";
    };
    "x86_64-darwin" = {
      asset = "pi-darwin-x64.tar.gz";
      hash = "sha256-OccKl1cFb9I45Me6GdpCfznbPOxS5JGlchA2aif0gGM=";
    };
    "aarch64-linux" = {
      asset = "pi-linux-arm64.tar.gz";
      hash = "sha256-KqOa9JBnYGty8WsCJQBgx4aEEewv4TJhJs+q/oN34GY=";
    };
    "x86_64-linux" = {
      asset = "pi-linux-x64.tar.gz";
      hash = "sha256-MWcUAL4mydyFGsInWeALAWCZsbMzavEL2/Sev1ob8/U=";
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
