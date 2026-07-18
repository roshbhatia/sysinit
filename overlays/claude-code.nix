_:

final: prev:
let
  version = "2.1.214";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-ZywqPN+toqfjmWtpGHXbxX603W4eT6pJSTmtgjPFQE4="; # autoupdate:src-hash
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
      hash = "sha256-HEy6B8R3Knbc8hXyNBxoHR4+scWOBwzs1wsolLsPEjM="; # autoupdate:npm-deps-hash
    };
  });
}
