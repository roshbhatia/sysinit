_:

final: prev:
let
  version = "2.1.210";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-IEhPKH5jxyQKvXNt5Jwv97gKEM8NedhIXEfMcXi3spE="; # autoupdate:src-hash
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
      hash = "sha256-6ENgkJvvKt6u3Uv1AXXpAw/lJkzLwnwGceUDbXJhJPM="; # autoupdate:npm-deps-hash
    };
  });
}
