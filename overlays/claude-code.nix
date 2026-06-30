_:

final: prev:
let
  version = "2.1.196";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Yaj9JMBQA0v7UQR/+LhDk+DYn9mkk2Iy1r2z/LU0+Iw="; # autoupdate:src-hash
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
      hash = "sha256-ISqaCvvU+57CwslOYP81f3K7gIbJPJVODF+v9rGktAU="; # autoupdate:npm-deps-hash
    };
  });
}
