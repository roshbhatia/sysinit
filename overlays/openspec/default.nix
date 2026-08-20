final: _prev:
let
  version = "1.10.0";

  pnpm22 = final.pnpm.override { nodejs-slim = final.nodejs-slim_22; };
in
{
  # Built from the git tag, not the npm tarball. Publish strips pnpm.overrides from
  # the manifest while every lockfile carries them, so --frozen-lockfile rejects the
  # tarball against any real lockfile. One tree keeps the two in agreement.
  openspec = final.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "openspec";
    inherit version;

    src = final.fetchFromGitHub {
      owner = "Fission-AI";
      repo = "OpenSpec";
      tag = "v${version}";
      hash = "sha256-4Sc0MUZu7pP/Pi189Kg6lsXtU5ZXEab5c1d/vkvnYrM=";
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
      hash = "sha256-HuVltL2c+acN1KHDSRD1lZu+Rn92jO7yp1np1g0oQRw=";
    };

    # The build needs the dev dependencies; what ships does not, and they are 100M.
    buildPhase = ''
      runHook preBuild
      pnpm run build
      pnpm prune --prod --ignore-scripts
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

    meta = with final.lib; {
      description = "OpenSpec CLI";
      homepage = "https://github.com/Fission-AI/OpenSpec";
      license = licenses.mit;
      mainProgram = "openspec";
    };
  });
}
