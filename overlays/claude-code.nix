_:

final: prev:
let
  version = "2.1.193";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Ekv6vfnslOposhXGRovqHYvcWC9vn+pghyEUXbu6zI4="; # autoupdate:src-hash
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
      hash = "sha256-TCGvOtrL62SmgFPIlvy5X3sXf0sII/Zvfo0IXZRANAs="; # autoupdate:npm-deps-hash
    };
  });
}
