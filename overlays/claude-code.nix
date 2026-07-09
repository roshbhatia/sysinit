_:

final: prev:
let
  version = "2.1.205";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-4AGjrJ7GxJas2y7JSjAa6vqAPIEwYq7FF6QdDgRNJjg="; # autoupdate:src-hash
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
      hash = "sha256-4Fxa7ivpXGiBGj6j1BN+tgzfUacwfyvtm4vfSxCIZ00="; # autoupdate:npm-deps-hash
    };
  });
}
