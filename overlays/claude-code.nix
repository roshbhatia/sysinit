_:

final: prev:
let
  version = "2.1.218";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-P23TcRNU1ZTP/CmelGWJzyVBTEYeZmQZfH2KhFQbm1Q="; # autoupdate:src-hash
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
      hash = "sha256-Kz8XWyEU2Pp63aP/trfl2dfY8tLhfj7xTfWoNnlxKIs="; # autoupdate:npm-deps-hash
    };
  });
}
