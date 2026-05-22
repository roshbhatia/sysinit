_:

final: prev:
let
  version = "2.1.147";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-NsDvob+MY4cKhLVg9FwLUQHx+ufIqNyjeSNo8kTdHeE="; # autoupdate:src-hash
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
      hash = "sha256-beiMQIc1ZzbIKhdGIivGB2Me6HeTt7rtGR+lP8qT9pc="; # autoupdate:npm-deps-hash
    };
  });
}
