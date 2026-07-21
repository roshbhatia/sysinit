_:

final: prev:
let
  version = "2.1.216";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-/jLXEzAUrtlM1xgDNmbEI5F6UAWt1R6Hw8x/2xRbW0g="; # autoupdate:src-hash
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
      hash = "sha256-GLTPuz+rJydIKs2wuTsa1/3bJ6JEDHe43u7HassSrzs="; # autoupdate:npm-deps-hash
    };
  });
}
