_:

final: prev:
let
  version = "2.1.152";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-E1dBZGEOqUFVi2tRemakIL1xoyj4Mwbu0glek2x7JzY="; # autoupdate:src-hash
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
      hash = "sha256-F/xmWO1AVqo2c7ryHeWQzxGDGQgDeM+BO660jzoHZ7Q="; # autoupdate:npm-deps-hash
    };
  });
}
