_:

final: prev:
let
  version = "2.1.156";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-b46S3Y7VEsxhd+cVViiEBOxBr8DP4ai9SgQqG6A8k48="; # autoupdate:src-hash
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
      hash = "sha256-2PRjEE1PR5TX0eXOTBtsVzWItirScAL+QCYBEzX6q0I="; # autoupdate:npm-deps-hash
    };
  });
}
