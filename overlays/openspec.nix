{ ... }:

final: _prev:
let
  version = "1.2.0";

  pnpmLock = final.fetchurl {
    url = "https://raw.githubusercontent.com/Fission-AI/OpenSpec/v${version}/pnpm-lock.yaml";
    hash = "sha256-g6JP/bYRmUUcgOs7/LqauqmEv2c+6IxxfHuA6yUjjdc=";
  };

  pnpmDeps = final.fetchPnpmDeps {
    pname = "openspec";
    inherit version;
    src = final.fetchurl {
      url = "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${version}.tgz";
      hash = "sha256-Ks7alGk/HbCw0uo8dQoqQYc36rMNAm0dBmYplFzemLo=";
    };
    sourceRoot = "package";
    prePatch = "cp ${pnpmLock} pnpm-lock.yaml";
    fetcherVersion = 3;
    hash = "sha256-q0ohsTq60CaQtMm8Qjx2aFvV/6LOn9Hr2ijLUDQY0MM=";
  };
in
{
  openspec = final.stdenvNoCC.mkDerivation {
    pname = "openspec";
    inherit version;

    src = final.fetchurl {
      url = "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${version}.tgz";
      hash = "sha256-Ks7alGk/HbCw0uo8dQoqQYc36rMNAm0dBmYplFzemLo=";
    };

    sourceRoot = "package";

    nativeBuildInputs = [
      final.nodejs
      final.pnpm.configHook
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
