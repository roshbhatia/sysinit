final: _prev:
let
  version = "2.2.0";
  targets = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha512-y3q/sghk/xCengTlv1pH2+5t9j0cuxXcEAY9yvyM7loKLQIYE1eSLEkDacCAVNyfnATd3D2JpueFSEB/i6A0Qg==";
    };
    x86_64-darwin = {
      name = "darwin-x64";
      hash = "sha512-oK46aktdkYIAlkFs72I4JNgFS+cEgrks/HAykoKXwcZTW3XlGY1GlhTfdp55XRw9XTfTCqHvtCtvD9IgCnGhQA==";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha512-NCCltb8h/8WL30X9o2KTm3UFX0lmfk48lG8tglXJN9moscxeB7w2qOmfHVa32iFngk0iVAKH4xRPlBc88Y0qlw==";
    };
    x86_64-linux = {
      name = "linux-x64";
      hash = "sha512-XTGFTiZTgugps6rgTXp4mPjOM8klsa5uHn/Shcms2o3k1bjSA3Sgl6O4yJ48y18WWxn9My5Pxt7JKcLID7LOHg==";
    };
  };
  target = targets.${final.stdenv.hostPlatform.system};
  # The website schemas change independently of the pinned CLI release.
  schemaDirectory = ./opencode-schemas + "/${version}";
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
