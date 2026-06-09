_:

final: prev:
let
  version = "2.1.169";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-9ThfJSNaNLWC9eXwYRYdk3dqbvnEOIg9JG6L6lCpWqo="; # autoupdate:src-hash
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
      hash = "sha256-ZpAlMEcS323F+zkbbxjYNxFG7eKt7UD1imqsHOVdPSw="; # autoupdate:npm-deps-hash
    };
  });
}
