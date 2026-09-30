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
  mcp-remote-go = final.buildGoModule {
    pname = "mcp-remote";
    version = "0.0.1";
    src = final.fetchFromGitHub {
      owner = "dezer32";
      repo = "mcp-remote";
      tag = "v0.0.1";
      hash = "sha256-gPcm0P60oDHHhUT0E5+b4ONIvvPMiqQVrU+HSIyIKGs=";
    };
    vendorHash = null;
    subPackages = [ "." ];
    patches = [ ./mcp-remote-oauth-discovery.patch ];
    checkPhase = ''
      runHook preCheck
      export GOFLAGS="''${GOFLAGS//-trimpath/}"
      go test -tags=integration ./...
      runHook postCheck
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
