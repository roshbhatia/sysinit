# Update to latest version:
#   VERSION=$(curl -s https://api.github.com/repos/badlogic/pi-mono/releases/latest | jq -r .tag_name | sed 's/^v//')
#   sed -i '' "s/version = \".*\"/version = \"$VERSION\"/" overlays/pi-coding-agent.nix
#   for pair in "aarch64-darwin:pi-darwin-arm64" "x86_64-darwin:pi-darwin-x64" "aarch64-linux:pi-linux-arm64" "x86_64-linux:pi-linux-x64"; do
#     plat=${pair%%:*}; asset=${pair#*:}
#     hash=$(nix-prefetch-url --type sha256 --unpack "https://github.com/badlogic/pi-mono/releases/download/v${VERSION}/${asset}.tar.gz" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri)
#     sed -i '' "/${plat}/,/hash =/{s|hash = \".*\"|hash = \"${hash}\"|;}" overlays/pi-coding-agent.nix
#   done
_:

final: _prev:
let
  version = "0.57.1";
  baseUrl = "https://github.com/badlogic/pi-mono/releases/download/v${version}";

  platformInfo = {
    "aarch64-darwin" = {
      asset = "pi-darwin-arm64.tar.gz";
      hash = "sha256-HqqKiKLE2cZbH4zOegsM4Xj1RRvx5vZQlhnb07Ja83A=";
    };
    "x86_64-darwin" = {
      asset = "pi-darwin-x64.tar.gz";
      hash = "sha256-y3jRArZ7dqHU19oqhOLIv/Ba8MWl9g8qvmQr2ORlBE8=";
    };
    "aarch64-linux" = {
      asset = "pi-linux-arm64.tar.gz";
      hash = "sha256-Ibd5dniFkcpV+O2iMCsbZ8JUbihxPnQtgiSvIwZdS6o=";
    };
    "x86_64-linux" = {
      asset = "pi-linux-x64.tar.gz";
      hash = "sha256-CW2vl/+hxa1HXQQTURQopuAZleIBq6cOZoxGpzvrizY=";
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
