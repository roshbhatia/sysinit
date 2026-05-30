_:

final: prev:
let
  version = "2.1.158";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-IKahf4yMd62+d68ZecFGTObjBTIchJpiGFGTDO2Uxcw="; # autoupdate:src-hash
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
      hash = "sha256-Qg2KGAZXc3z5DqYUjuWR99BFVpN8E+8eou/RFXwzaq0="; # autoupdate:npm-deps-hash
    };
  });
}
