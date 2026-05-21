_:

final: prev:
let
  version = "2.1.146";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-gnkIzMdyDzgdjpE6eT1a8PKLJtgFlEgAz01lCirYtpU="; # autoupdate:src-hash
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
      hash = "sha256-VjVhPtWSDxc6loqmPOlYM2VMChKRmr+Ak5feJJ6vqXM="; # autoupdate:npm-deps-hash
    };
  });
}
