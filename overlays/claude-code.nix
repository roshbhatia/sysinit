_:

final: prev:
let
  version = "2.1.170";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-sdyk0bXhk0GFClCIGjtrn5PJfchdD0kGCyUDlMpSXGY="; # autoupdate:src-hash
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
      hash = "sha256-2ENkfyzjAjbeUe655znpOmyVSE7n2iONSz5yJhiBpiw="; # autoupdate:npm-deps-hash
    };
  });
}
