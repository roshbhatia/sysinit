final: prev: {
  strands-cli = prev.buildNpmPackage {
    pname = "strands-cli";
    version = "0.1.2";
    src = ./strands;
    npmDepsHash = "sha256-qwj8XfpV/PlzqZYs2Gq+9DkVX5Jjy77nLcBeeZ9zAuI=";
    npmFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;

    nativeBuildInputs = [
      prev.makeWrapper
    ]
    ++ prev.lib.optional prev.stdenv.hostPlatform.isLinux prev.autoPatchelfHook;
    buildInputs = prev.lib.optional prev.stdenv.hostPlatform.isLinux prev.stdenv.cc.cc.lib;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/strands
      cp -r node_modules package.json $out/lib/strands/
      makeWrapper ${prev.nodejs}/bin/node $out/bin/strands \
        --add-flags $out/lib/strands/node_modules/@strands-agents/cli/bin/strands.js \
        --set-default STRANDS_CLI_TELEMETRY off
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      test "$($out/bin/strands --version)" = "0.1.2"
      $out/bin/strands --help | grep -F -- --acp-server
      cd $out/lib/strands
      ${prev.nodejs}/bin/node --input-type=module -e \
        'import { createHarness } from "@strands-agents/harness"; if (typeof createHarness !== "function") process.exit(1)'
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "Strands terminal agent with the Strands harness runtime";
      homepage = "https://github.com/strands-agents/harness-sdk";
      license = licenses.asl20;
      mainProgram = "strands";
      platforms = platforms.unix;
    };
  };
}
