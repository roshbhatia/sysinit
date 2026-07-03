_:

final: prev:
let
  version = "2.1.200";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-F6XSzt79G9YIsb4jQTlvnXbtmN9Wug/wscO4K6RCJak="; # autoupdate:src-hash
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
      hash = "sha256-a9g9FzrSvZ/SZM+PbMPk5HkJt2BkzP5dH2QX/i+8wMY="; # autoupdate:npm-deps-hash
    };
  });
}
