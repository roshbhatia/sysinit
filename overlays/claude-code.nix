_:

final: prev:
let
  version = "2.1.201";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-kgVdrLJTgyKGGDdbGF2TQTI3eRNJglHM1bqzKMOm6/U="; # autoupdate:src-hash
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
      hash = "sha256-Uath95aoa/EQ09pMOzQwF6JKo9LrossuS8tz+FYDqF8="; # autoupdate:npm-deps-hash
    };
  });
}
