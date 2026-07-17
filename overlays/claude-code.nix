_:

final: prev:
let
  version = "2.1.212";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-a7F5v0ohH4U0qvzmyYFXcN5FsBfgyb5IikuPuRamCsg="; # autoupdate:src-hash
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
      hash = "sha256-jMPKZmuI7bTzS5Z9jHVoD8N909gDHo34sG0OIOKsZN4="; # autoupdate:npm-deps-hash
    };
  });
}
