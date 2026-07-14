_:

final: prev:
let
  version = "2.1.209";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-cDongZ4SZ7blW+eOA04qN5PuRBmpenZufJe6p1v8IRM="; # autoupdate:src-hash
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
      hash = "sha256-4RArwpWkdEA4zu1wUjfy8Yoqhj+CyhWipEDLz2IZxFk="; # autoupdate:npm-deps-hash
    };
  });
}
