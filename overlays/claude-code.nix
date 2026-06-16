_:

final: prev:
let
  version = "2.1.178";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-UM02eJ4IIB+VtzerM8ovWD+cuF6tZDAlJvzW7sWRfKs="; # autoupdate:src-hash
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
      hash = "sha256-Jgx2t6gylLnuXOM2jRCHk1JRLnLD0fQ5jERN39zM1/0="; # autoupdate:npm-deps-hash
    };
  });
}
