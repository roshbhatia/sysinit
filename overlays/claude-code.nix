_:

final: prev:
let
  version = "2.1.190";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-734U+xjNj8gTLZweYVM0UR+CdZHF4gqQND2Jxoww5+A="; # autoupdate:src-hash
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
      hash = "sha256-Bi/DZIAyM6Lci2j1Hp1E+IyIWwWrPIYfdq+B8hDCn+s="; # autoupdate:npm-deps-hash
    };
  });
}
