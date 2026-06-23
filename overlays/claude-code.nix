_:

final: prev:
let
  version = "2.1.186";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-qN6YS42YkWWomuaX3p6+xdtgZSD/G9QgpkyONXbpgSw="; # autoupdate:src-hash
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
      hash = "sha256-RF+NR7ieejy7xJr336GsWw10M9iwkQdqLtMXNCia6rw="; # autoupdate:npm-deps-hash
    };
  });
}
