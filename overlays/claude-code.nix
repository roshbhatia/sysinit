_:

final: prev:
let
  version = "2.1.144";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Xptx79JU0YiY2gCOkJSfTHDiZHoLDB1zqYlyUu0/KnU="; # autoupdate:src-hash
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
      hash = "sha256-313tcEzRTMME7UHu2WZ3dUse9dv+zR6yW+4NXmv1Dsk="; # autoupdate:npm-deps-hash
    };
  });
}
