_:

final: prev:
let
  version = "2.1.197";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Zqgs2Rzp0cH6W2XSb2/vCEQ2NAT5o8r5FzYutTLzZGs="; # autoupdate:src-hash
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
      hash = "sha256-9GbCHZX24apl3teLWt0Zl28pKC7p/NK4JHVPWm4JXjk="; # autoupdate:npm-deps-hash
    };
  });
}
