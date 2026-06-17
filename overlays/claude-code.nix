_:

final: prev:
let
  version = "2.1.179";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-9Cz8efA9CJ80R8owjHG+2EU5C7Pz0cR0XGPNfvqBTXc="; # autoupdate:src-hash
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
      hash = "sha256-rv0yhk/eGRhYDejiBtNZv1eNYtvSWTe+OVgOKPl3Dcg="; # autoupdate:npm-deps-hash
    };
  });
}
