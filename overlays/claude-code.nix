_:

final: prev:
let
  version = "2.1.173";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-ucB+sPuzy6kxzUqYbtofmoDB9/If5EIjIi1uoRyHHfg="; # autoupdate:src-hash
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
      hash = "sha256-MPOJRyvUmQWaiP114WlA/NyZgPBgbfwifXwNR4Cik0o="; # autoupdate:npm-deps-hash
    };
  });
}
