final: _prev:
let
  version = "1.15.0";

  pnpm22 = final.pnpm_10.override { nodejs-slim = final.nodejs-slim_22; };
in
{

  openspec = final.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "openspec";
    inherit version;

    src = final.fetchFromGitHub {
      owner = "Fission-AI";
      repo = "OpenSpec";
      tag = "v${version}";
      hash = "sha256-knAHLCUbZ/GVrlhiq1F0C7tq6/Uj6dp1haxIliAQEUI="; # autoupdate:src-hash
    };

    nativeBuildInputs = [
      final.nodejs
      pnpm22
      final.pnpmConfigHook
      final.makeWrapper
    ];

    pnpmDeps = final.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      pnpm = pnpm22;
      fetcherVersion = 4;
      hash = "sha256-T02CCNDZg9lsIgpEGmkEqptN/kPiT4uXX68LTNd7XW0="; # autoupdate:pnpm-deps-hash
    };

    buildPhase = ''
      runHook preBuild
      pnpm run build
      pnpm prune --prod --ignore-scripts
      # pnpm leaves internal links to removed development dependencies after pruning.
      find node_modules/.pnpm/node_modules -xtype l -delete
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/openspec $out/bin
      cp -r bin dist schemas package.json node_modules $out/lib/openspec/
      makeWrapper ${final.nodejs}/bin/node $out/bin/openspec \
        --add-flags "$out/lib/openspec/bin/openspec.js"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      $out/bin/openspec --version | grep -Fx '${version}'
      $out/bin/openspec --help > /dev/null
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "OpenSpec CLI";
      homepage = "https://github.com/Fission-AI/OpenSpec";
      license = licenses.mit;
      mainProgram = "openspec";
    };
  });
}
