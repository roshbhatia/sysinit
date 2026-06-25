_:

final: prev:
let
  version = "2.1.191";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-dxW9VbVYel22l0AiB8CTRRe6Gqpnon84/YNtx2uL1Gs="; # autoupdate:src-hash
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
      hash = "sha256-W6n6Del7Nvy+GdICXBYzSWTA89kTFl+MAWZIggcupaY="; # autoupdate:npm-deps-hash
    };
  });
}
