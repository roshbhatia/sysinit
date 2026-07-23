_:

final: _prev:
let
  version = "1.6.0";

  # Node 24's libuv double-closes a guarded fd from a worker thread during
  # process teardown on macOS, so pnpm (which uses worker threads to link its
  # store) gets EXC_GUARD-killed (`Killed: 9` / exit 137) right after a
  # successful `pnpm install`. Pin pnpm to Node 22 LTS to dodge the regression.
  # The pnpmDeps output is content-addressed (recursive hash), so swapping the
  # build-time Node does not change the autoupdate-managed FOD hash.
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

    # Make rosh-spec-driven the machine-wide default. openspec has no config
    # key for a default schema; the default is hardcoded across six sites in
    # the prebuilt dist/. Patch every site, not just the named constants:
    # `openspec new change` reads `root.defaultSchema` from the inline
    # object-literal in root-selection.js, which is not a named constant.
    # --replace-fail makes a missed site (upstream rename on a version bump)
    # fail the build loudly instead of silently reverting to spec-driven.
    # A newly *added* controlling site is caught by the behavioral flake check
    # (checks.<system>.openspec-default-schema), not here.
    postPatch = ''
      substituteInPlace dist/core/openspec-root.js \
        --replace-fail "DEFAULT_OPENSPEC_SCHEMA = 'spec-driven'" "DEFAULT_OPENSPEC_SCHEMA = 'rosh-spec-driven'"
      substituteInPlace dist/core/init.js \
        --replace-fail "DEFAULT_SCHEMA = 'spec-driven'" "DEFAULT_SCHEMA = 'rosh-spec-driven'"
      substituteInPlace dist/commands/workflow/shared.js \
        --replace-fail "DEFAULT_SCHEMA = 'spec-driven'" "DEFAULT_SCHEMA = 'rosh-spec-driven'"
      substituteInPlace dist/utils/change-utils.js \
        --replace-fail "DEFAULT_SCHEMA = 'spec-driven'" "DEFAULT_SCHEMA = 'rosh-spec-driven'"
      substituteInPlace dist/core/planning-home.js \
        --replace-fail "REPO_DEFAULT_SCHEMA = 'spec-driven'" "REPO_DEFAULT_SCHEMA = 'rosh-spec-driven'"
      substituteInPlace dist/core/root-selection.js \
        --replace-fail "defaultSchema: 'spec-driven'" "defaultSchema: 'rosh-spec-driven'"
    '';

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
