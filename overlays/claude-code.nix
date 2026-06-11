_:

final: prev:
let
  version = "2.1.172";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-IC2OJKU/8LsluctpMUyBxe/on29kAWRHLqEu3bsXcMc="; # autoupdate:src-hash
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
      hash = "sha256-liS22ODZcFkqGQQqTJRhtEOkhWR3VUr2p1vOJ/ykyVg="; # autoupdate:npm-deps-hash
    };
  });
}
