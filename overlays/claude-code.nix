_:

final: prev:
let
  version = "2.1.150";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-ZV03EuQiC3rHbu84chQupmcnUNfpzyKbwcy81icqh6w="; # autoupdate:src-hash
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
      hash = "sha256-pRurEULi+A1C1biWhK2hn2mZ8/uuZAOsHSSS0c36os4="; # autoupdate:npm-deps-hash
    };
  });
}
