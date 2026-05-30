_:

final: prev:
let
  version = "2.1.157";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-p/Rs99nu52MjBhUL4/u4LhCh7JJv0Fjmsn2GyepYML8="; # autoupdate:src-hash
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
      hash = "sha256-xAwbi7gcBPiACl9C/lbmNHgz9yjOSeTh5EAPfOpnvwE="; # autoupdate:npm-deps-hash
    };
  });
}
