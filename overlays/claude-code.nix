_:

final: prev:
let
  version = "2.1.207";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-wGBg5O6Wjvd8KAuQ659iLf5dlgz+hyguOB/u0g/sgYw="; # autoupdate:src-hash
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
      hash = "sha256-owtsEPIw7DqWReXSKjcOwiNYZPefwXpO65MdgSekXGs="; # autoupdate:npm-deps-hash
    };
  });
}
