_:

final: prev:
let
  version = "2.1.165";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-zz/PQOWpl5j5M/NBYwNV5Oc4BvHEkB097GjaB+hwx6w="; # autoupdate:src-hash
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
      hash = "sha256-ak9vQmTl+PrRlFMkNgDyR4hWn1KKy3/Fe6nPeL5edcQ="; # autoupdate:npm-deps-hash
    };
  });
}
