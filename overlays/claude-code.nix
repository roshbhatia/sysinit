_:

final: prev:
let
  version = "2.1.195";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-CJYn8VDP7BfXXUZxnAGVVOlkt57VxlYkLIqaNzBBDpc="; # autoupdate:src-hash
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
      hash = "sha256-ZklpQQjleWp9YBpUWMi95E1h9TrRJBhaMOt6iTCSXj4="; # autoupdate:npm-deps-hash
    };
  });
}
