_:

final: prev:
let
  version = "2.1.163";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-xu5NjCWwEqYOZeeMvRcjaN/OE3s3htO5fa/0Zs8vUOU="; # autoupdate:src-hash
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
      hash = "sha256-+hHZ7ECk0qyRbIGgQOGv6D1to4BKaWqxeL7X098eHmc="; # autoupdate:npm-deps-hash
    };
  });
}
