final: _prev:
let
  version = "2.0.15";
  targets = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha512-qIFmkv6f01Deih/DH+OvblNQEZrAUal54PjUHLu61zS5OYCpXnRjkYWHV3RiEZhP5DtfQZsJeitmMW5v6f2NTw==";
    };
    x86_64-darwin = {
      name = "darwin-x64";
      hash = "sha512-A0SMRL+ijMxUcWbF3b+4+3W1Uc/Jyt64DXCeIcZL+Vc4blDZVqqm2e4/uzrTJX6tpoUbBHIAFO6fF4WOH8BsVg==";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha512-AAowG3XMBi7RwhEp/j2oaa4GuNZB0bEUe/fyFKMgkoKKbqssPkjKB+U3ZeEzXCzb/zgR1kgi/+OiUVzTd4iv1w==";
    };
    x86_64-linux = {
      name = "linux-x64";
      hash = "sha512-PGVHuIb6uDgCx19zbD3wGwDYBZLeZnZY89c28SCcB87ckAgfOp+L2o7rra1TMbyQVLhZAqccbymWDeqrynfOCA==";
    };
  };
  target = targets.${final.stdenv.hostPlatform.system};
  configSchema = final.fetchurl {
    url = "https://opencode.ai/config.json";
    hash = "sha256-6MtuKHo4Uu40A/SAO+WtaxnblJSAN+qpZyElwzNCeSI=";
  };
  cliSchema = final.fetchurl {
    url = "https://opencode.ai/v2/cli.json";
    hash = "sha256-n39jJiazCt6qPUBVejcinG+GKCdML5uavcg2EgC2e+4=";
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
    postFixup = ''
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
