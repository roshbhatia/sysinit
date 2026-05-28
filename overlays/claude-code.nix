_:

final: prev:
let
  version = "2.1.154";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-GwvB6XoZox3ELOQXIfIBKcmxqgVs5Tp1RvA+RGu9rrc="; # autoupdate:src-hash
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
      hash = "sha256-T0wuxrySGyleAXDDI4qJ0zfmPC9Zw33zxKI9LeCzP0k="; # autoupdate:npm-deps-hash
    };
  });
}
