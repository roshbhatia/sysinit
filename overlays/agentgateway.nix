final: _prev:
let
  assets = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha256:6cebe8bd57262edce23a65a376d2f5a27b97cdfef609740642edbe75e1e9c685";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha256:b59ecac31103bb317d1377fd42b0cb25cd9a21f8c3f1d9ee14c3ff05f3f91abf";
    };
    x86_64-linux = {
      name = "linux-amd64";
      hash = "sha256:496ed27e6a96b55a9ad7cabe5c2be7172511f44a3cb113e533d22bf93a7f079d";
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
    version = "1.6.0";
    src = final.fetchurl {
      url = "https://github.com/agentgateway/agentgateway/releases/download/v1.6.0/agentgateway-${asset.name}";
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
