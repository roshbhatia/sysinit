_:

final: prev:
let
  version = "2.1.141";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-qSD+T6j6xeJZ+lKtCJxjrKtMFzPH5LIPOIoyUF1vwO0="; # autoupdate:src-hash
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
      hash = "sha256-Qc2/hrzVbHOgtDBb5NxjMECc5IxTPoxVZnK8+8OrDHs="; # autoupdate:npm-deps-hash
    };
  });
}
