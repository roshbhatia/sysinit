_:

final: prev:
let
  version = "2.1.177";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-uzSTB+4sbK/mpMbN8q/gpjjV5abYF5x19KUN5fSRcrw="; # autoupdate:src-hash
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
      hash = "sha256-hSz2Ho53Qan9h9pqP+/1DbrPhtu44fLFycysepIl/q8="; # autoupdate:npm-deps-hash
    };
  });
}
