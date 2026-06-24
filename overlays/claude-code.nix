_:

final: prev:
let
  version = "2.1.187";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-z09FIi9S+emBTMeXe6HVZmUZE+kKKSYBxxi1vcan5GE="; # autoupdate:src-hash
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
      hash = "sha256-37dsAW187KziiSMLaZVenF5MNje0j1iFNKcBtDQEepE="; # autoupdate:npm-deps-hash
    };
  });
}
