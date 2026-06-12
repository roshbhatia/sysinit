_:

final: prev:
let
  version = "2.1.175";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-T4/6bV3ezPeNLdV7gqOZ8luTyki1YvwSN5K+6DA3SpM="; # autoupdate:src-hash
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
      hash = "sha256-iCB9t7LYF3PdRWaQCaHgWL58Rvc4/JiPAf6OVyEFwPs="; # autoupdate:npm-deps-hash
    };
  });
}
