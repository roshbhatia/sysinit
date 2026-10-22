final: _prev:
let
  version = "2.0.30";
  targets = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha512-pXiRPtYr8BERCcx4/dUzCUra3vxsQffTa/8l6rjODNBgWAoxLlWJaXxrGmQ907uRPaUY0OT7HQvTmUzRTnkj9g==";
    };
    x86_64-darwin = {
      name = "darwin-x64";
      hash = "sha512-jUcKqt0bAqFix5nlLOAvVcwS1bLHicmYG6CxeMWPtNfIADu17GwcJt7HRL86VoXXykRAy9pk7mHYWsPyQYfcFQ==";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha512-EQzVA40jWkbYMQGdqC3y7I7DOUnw5zYhPPwCa2vFb/MK/BuBkHZqPcsDABD82ECaNVGJo43kz8s0Ckodb8EA4w==";
    };
    x86_64-linux = {
      name = "linux-x64";
      hash = "sha512-oBw8dtg9BWiKkhyPOxA6GN+o78zmQfjgVi7Hz9de1pJZJVyGBMLlkYk1EwPeS+vWyOCSaty2FxCAsYH1bMdS2g==";
    };
  };
  target = targets.${final.stdenv.hostPlatform.system};
  configSchema = final.fetchurl {
    url = "https://opencode.ai/config.json";
    hash = "sha256-pYLvqyhe3rsyDS+m0uR1DsT+DliOivDkE9Yw5bzhxbk=";
  };
  cliSchema = final.fetchurl {
    url = "https://opencode.ai/v2/cli.json";
    hash = "sha256-GZ2aDEQIR7peaJdl/uN9hzCOP38F3Po2j5l/LTbffo4=";
  };
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
      cp ${configSchema} "$out/share/config.json"
      cp ${cliSchema} "$out/share/cli.json"
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
