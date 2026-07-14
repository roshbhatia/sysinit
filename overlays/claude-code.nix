_:

final: prev:
let
  version = "2.1.208";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-0a7xjgD+5ntEHx069+4ZPtFTYe1Z7rhkwqDzyEv+nDk="; # autoupdate:src-hash
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
      hash = "sha256-3jYtxUnAH1JGepLE+Twuo2z+o4yESJ/uAeyfRmAnCOU="; # autoupdate:npm-deps-hash
    };
  });
}
