_final: prev:
let
  version = "2.1.233";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-sV/PWPzTmHLfwjHo5QR24Djzb3TsGHAE7myJ8SBxqks=";
  };
in
{
  claude-code = prev.claude-code.overrideAttrs (_old: {
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
      hash = "sha256-IIVM1EdkyylttmYd6jehczSspbfDzbdHA37Ig9pp5pA=";
    };
  });
}
