_:

final: prev:
let
  version = "2.1.143";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-y8hdOjAOsC+kUIO1ez1zcmgxKq+JyaxbJyQc0a3Cb9A="; # autoupdate:src-hash
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
      hash = "sha256-Kt4XI4xNTaG5KlCMmZ4RvUGh5+CmqWrqt78ZsnevP3c="; # autoupdate:npm-deps-hash
    };
  });
}
