_:

final: prev:
let
  version = "2.1.185";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-a0WBZ76f9QOqQqJxDmebSEGsj0BX/gs0XiWPylcp8Ms="; # autoupdate:src-hash
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
      hash = "sha256-q9IpuDXG8aIv/Tn5bkqp1SYAfeoU0lVRFBQbntg6+GI="; # autoupdate:npm-deps-hash
    };
  });
}
