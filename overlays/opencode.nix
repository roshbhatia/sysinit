final: _prev:
let
  version = "2.4.1";
  targets = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha512-r6PIZl5wqFxVYfVFjm2JK4uf1a3YT7FMEVTODJF/1hKe6wBdK7THzbAM1SSyuRuMnSkDb9+dd8xNOk9zQK6trg==";
    };
    x86_64-darwin = {
      name = "darwin-x64";
      hash = "sha512-J/khLpe0pisTGDD5jpddQjqb5e8qUsWYpiRkqIBN3a/P4S5asfP2ErLKSevmpGzhg9fC1TpLJnGVXwgN+JJgKg==";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha512-olNKfoAuHaDtHrWrlqxh2RPSonSfAZPGJlru7tMNeNTlHyLSrTbDe/+HJ6vdYRp7g4yKLSQ8SG264U/IC7Pgtw==";
    };
    x86_64-linux = {
      name = "linux-x64";
      hash = "sha512-FYQAnneVlLmqy862674vvRVkj8yHuZAFHJGV3UCGQxo8aKG58IHPKrspbxruVajnIEpb0t8PeO63H/oW4vJG5A==";
    };
  };
  target = targets.${final.stdenv.hostPlatform.system};
  # The website schemas change independently of the pinned CLI release.
  schemaDirectory = ./opencode-schemas/2.2.0;
in
{
  opencode = final.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;
    src = final.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-${target.name}/-/cli-${target.name}-${version}.tgz";
      inherit (target) hash;
    };
    sourceRoot = "package";
    nativeBuildInputs = [
      final.installShellFiles
      final.jq
    ]
    ++ final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.autoPatchelfHook ];
    buildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.stdenv.cc.cc.lib ];
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 bin/opencode "$out/bin/opencode"
      ln -s opencode "$out/bin/opencode2"
      mkdir -p "$out/share"
      cp ${schemaDirectory}/config.json "$out/share/config.json"
      cp ${schemaDirectory}/cli.json "$out/share/cli.json"
      install -Dm644 ${schemaDirectory}/LICENSE "$out/share/licenses/opencode/LICENSE"
      runHook postInstall
    '';
    postPhases = [ "installCompletionsPhase" ];
    installCompletionsPhase = ''
      export HOME="$TMPDIR"
      installShellCompletion --cmd opencode \
        --zsh <("$out/bin/opencode" --completions zsh) \
        --bash <("$out/bin/opencode" --completions bash) \
        --fish <("$out/bin/opencode" --completions fish)
      substituteInPlace "$out/share/zsh/site-functions/_opencode" \
        --replace-fail '#compdef opencode' '#compdef opencode opencode2'
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      export HOME="$TMPDIR"
      test "$("$out/bin/opencode" --version)" = "opencode v${version}"
      test "$("$out/bin/opencode2" --version)" = "opencode v${version}"
    '';
    meta = {
      description = "OpenCode v2 terminal agent";
      homepage = "https://opencode.ai/v2";
      license = final.lib.licenses.mit;
      platforms = builtins.attrNames targets;
      mainProgram = "opencode";
    };
  };
}
