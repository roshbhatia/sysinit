_:

final: prev:
let
  version = "2.1.160";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-DZfdNzVzQJErJ+2aPPo4AM8oEYBpa6Tf8Svs6hViTNc="; # autoupdate:src-hash
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
      hash = "sha256-GQI+3GLS6ZZ5fZ4MtKI9GWOiwg6Y+2DrwVwuqf1pysU="; # autoupdate:npm-deps-hash
    };
  });
}
