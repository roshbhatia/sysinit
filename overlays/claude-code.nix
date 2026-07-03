_:

final: prev:
let
  version = "2.1.199";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Zp2OPNJyX7QJmGdh/mhfKq5s9Jncq6/184g988jma1A="; # autoupdate:src-hash
  };
in
{
  claude-code = prev.claude-code.overrideAttrs (old: {
    inherit version src;
    postPatch = ''
      cp ${./claude-code-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      name = "claude-code-${version}-npm-deps";
      inherit src;
      postPatch = ''
        cp ${./claude-code-package-lock.json} package-lock.json
      '';
      hash = "sha256-4yTKcmseKyIkspsTVlRvvREKIsq11ANX9uGiaXPFiy4="; # autoupdate:npm-deps-hash
    };
  });
}
