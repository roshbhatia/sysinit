_:

final: prev:
let
  version = "2.1.181";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-I4reMcEq3WyxW8hYttPS+Au1UCuWcc0hUiJcWh2sChA="; # autoupdate:src-hash
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
      hash = "sha256-DJhf11E7rgRpYmFTKF2rPO3UNaD5X2PAVEsdftpaHQo="; # autoupdate:npm-deps-hash
    };
  });
}
