_:

final: prev:
let
  version = "2.1.204";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-y54aQBibpZLs5q7bsbR8cTGlHjUjhVtg939PauIeQvQ="; # autoupdate:src-hash
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
      hash = "sha256-MfXycBh0v15cyer2EqTBPQSpINy6u5JO30W5lmd5+go="; # autoupdate:npm-deps-hash
    };
  });
}
