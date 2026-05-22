_:

final: prev:
let
  version = "2.1.148";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-kgpljneBGSKcmfd7e5GpRlLFWGdTpyZLh/jTgqVc26U="; # autoupdate:src-hash
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
      hash = "sha256-so8SdQgvOXOIq8KpseB2XjR+uv+C0p7M6B+elb9gYBI="; # autoupdate:npm-deps-hash
    };
  });
}
