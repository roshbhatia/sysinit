_:

final: prev:
let
  version = "2.1.140";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-TPTrpyB7rCTs53zhc/F4jnbNdo+cw33ZHC5wzyQDing="; # autoupdate:src-hash
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
      hash = "sha256-3xy2vt2gypmcGz6a/wPRDHz5OwYVCOyC0iiyHHIaOKw="; # autoupdate:npm-deps-hash
    };
  });
}
