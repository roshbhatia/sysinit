final: _prev:
let
  assets = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha256:34bfc961d0e459d0f89103100e61730d4b5d8e2151c851d33cd034a126eb2bfe";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha256:85724a15dc9f5179fb6e2fd85b0ba2d4fea56dd289abb8bf8fefadc3bea8b89e";
    };
    x86_64-linux = {
      name = "linux-amd64";
      hash = "sha256:1b2fc01a2de29ca113bbb6258b5cae7b1eb3c724071c09d687a449132f2f42f8";
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
    version = "1.7.0";
    src = final.fetchurl {
      url = "https://github.com/agentgateway/agentgateway/releases/download/v1.7.0/agentgateway-${asset.name}";
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
