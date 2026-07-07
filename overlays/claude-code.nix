_:

final: prev:
let
  version = "2.1.202";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-iYMzS087DRSow8AokaE4RIFl8pWlAxioW3N6GDAM1d0="; # autoupdate:src-hash
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
      hash = "sha256-DJS/wtN8g9sLf7GeSdd9njYNk6Va09OS2ObZ5ldAGKk="; # autoupdate:npm-deps-hash
    };
  });
}
