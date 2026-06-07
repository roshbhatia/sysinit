_:

final: prev:
let
  version = "2.1.168";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-CmEESVkvMJtROO5t66PEdOD20rKz9K8iJE8Zhy3pj8g="; # autoupdate:src-hash
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
      hash = "sha256-+Zp2pt1gRZDjDOcc6vyq8SWDAT477LQEwa01o/Wv2hY="; # autoupdate:npm-deps-hash
    };
  });
}
