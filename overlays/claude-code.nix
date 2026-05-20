_:

final: prev:
let
  version = "2.1.145";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-eMveVpnasmHQ7c5Lv6dyJSBpItDJj/shLRtKDUJwYzo="; # autoupdate:src-hash
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
      hash = "sha256-bOmbKPAlNQcCns3Bk5H4PJ1UwbJibVWCWnaoGIeQnOg="; # autoupdate:npm-deps-hash
    };
  });
}
