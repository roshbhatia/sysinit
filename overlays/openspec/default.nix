final: _prev:
let
  version = "1.6.0";

  pnpm22 = final.pnpm.override { nodejs-slim = final.nodejs-slim_22; };

  pnpmLock = final.fetchurl {
    url = "https://raw.githubusercontent.com/Fission-AI/OpenSpec/v${version}/pnpm-lock.yaml";
    hash = "sha256-P7NIBR4092b5KRPhElNN54C4pQ5g9VsQFBZcQ42v50s="; # autoupdate:pnpm-lock-hash
  };

  pnpmDeps = final.fetchPnpmDeps {
    pname = "openspec";
    inherit version;
    pnpm = pnpm22;
    src = final.fetchurl {
      url = "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${version}.tgz";
      hash = "sha256-qAR3dn6Ypi6VZGStCaRLKMrMT8v94jdl97S6WY7hOFk="; # autoupdate:src-hash
    };
    sourceRoot = "package";
    prePatch = "cp ${pnpmLock} pnpm-lock.yaml";
    fetcherVersion = 4;
    hash = "sha256-dSZs+yWyLDbY8k5lizLa8W/ZAOWzgi88ysnyZiA7yTA="; # autoupdate:pnpm-deps-hash
  };
in
{
  openspec = final.stdenvNoCC.mkDerivation {
    pname = "openspec";
    inherit version;

    src = final.fetchurl {
      url = "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${version}.tgz";
      hash = "sha256-qAR3dn6Ypi6VZGStCaRLKMrMT8v94jdl97S6WY7hOFk="; # autoupdate:src-hash
    };

    sourceRoot = "package";

    nativeBuildInputs = [
      final.nodejs
      pnpm22
      final.pnpmConfigHook
      final.makeWrapper
    ];

    inherit pnpmDeps;

    prePatch = "cp ${pnpmLock} pnpm-lock.yaml";

    buildPhase = ''
      runHook preBuild
      pnpm install --frozen-lockfile --prod
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/openspec $out/bin
      cp -r . $out/lib/openspec/
      makeWrapper ${final.nodejs}/bin/node $out/bin/openspec \
        --add-flags "$out/lib/openspec/bin/openspec.js"
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "OpenSpec CLI";
      homepage = "https://github.com/Fission-AI/OpenSpec";
      license = licenses.mit;
      mainProgram = "openspec";
    };
  };
}
