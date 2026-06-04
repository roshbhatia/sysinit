_:

final: prev:
let
  version = "2.1.162";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-7lfJPxW9MdcyaBn9bI//b0Ijo/AGEvyeBm+ki5fBxCk="; # autoupdate:src-hash
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
      hash = "sha256-iAOo/VUgFU6w7EOSV9J95BjLsy0wpeNlJj0OBq8AZmQ="; # autoupdate:npm-deps-hash
    };
  });
}
