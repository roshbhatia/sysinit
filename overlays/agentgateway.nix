final: _prev:
let
  assets = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha256-2kMtNb1pbaBWT3sra7x4NUK2ucYW1sDE1MPa7536EaE=";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha256:61f12dbb99669aa4b97b85a0040183fe4b098fa0a82a8c389665fe606517c13e";
    };
    x86_64-linux = {
      name = "linux-amd64";
      hash = "sha256:daca5cda76e8c5ab0c1a75912fecf2d6365095403f810db72029c49d14a37e7b";
    };
  };
  asset = assets.${final.stdenv.hostPlatform.system};
in
{
  mcp-remote-go = final.stdenvNoCC.mkDerivation {
    pname = "mcp-remote";
    version = "0.0.1";
    src = final.fetchurl {
      url = "https://github.com/dezer32/mcp-remote/releases/download/v0.0.1/mcp-remote_0.0.1_${
        builtins.replaceStrings [ "-" ] [ "_" ] asset.name
      }.tar.gz";
      hash =
        {
          aarch64-darwin = "sha256-bTIxn9uDE4WJ7exe3yjDmO6WNQDY8Ffjl03BrUwKSwI=";
          aarch64-linux = "sha256:f48e06b6d1a750e24bf718cc37805fd2f93685fcd4dfe76c96462d8342f1a074";
          x86_64-linux = "sha256:04d7812374a8650261c30b77b82c9b57e2f245bfcbd3f317b77e27567052cd42";
        }
        .${final.stdenv.hostPlatform.system};
    };
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 mcp-remote "$out/bin/mcp-remote"
    '';
    meta = {
      mainProgram = "mcp-remote";
      platforms = builtins.attrNames assets;
      license = final.lib.licenses.mit;
    };
  };
  agentgateway = final.stdenvNoCC.mkDerivation {
    pname = "agentgateway";
    version = "1.5.0";
    src = final.fetchurl {
      url = "https://github.com/agentgateway/agentgateway/releases/download/v1.5.0/agentgateway-${asset.name}";
      inherit (asset) hash;
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 "$src" "$out/bin/agentgateway"
    '';
    meta = {
      mainProgram = "agentgateway";
      platforms = builtins.attrNames assets;
      license = final.lib.licenses.asl20;
    };
  };
}
