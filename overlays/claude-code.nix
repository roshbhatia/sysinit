_:

final: prev:
let
  version = "2.1.149";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-o88kFbfefp6TZwG6mgu7MUc/f9eYQhXnYGTbsSoJf9Y="; # autoupdate:src-hash
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
      hash = "sha256-cf3A7eEBxOwTQqvPYlCLcOqT/2qzAPkTm2iuTueoYh0="; # autoupdate:npm-deps-hash
    };
  });
}
