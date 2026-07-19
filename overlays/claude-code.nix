_:

final: prev:
let
  version = "2.1.215";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-AK786vtyXTeM+McfIaFpHXTNbqFwk7CpmJecwS1WNvs="; # autoupdate:src-hash
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
      hash = "sha256-H/Zs3sTDcve9kORUHuAexr0CGV7/KbsIMtbN+ZuJUcM="; # autoupdate:npm-deps-hash
    };
  });
}
